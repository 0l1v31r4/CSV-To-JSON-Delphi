unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, System.Generics.Collections, REST.Json, System.RegularExpressions,
  Vcl.ComCtrls, FireDAC.UI.Intf, FireDAC.VCLUI.Async, FireDAC.Stan.Intf,
  FireDAC.Comp.UI;

type
  TFieldType = (ftNoneType, ftCardial, ftString, ftDateTime);
  TItemLista = class
    private
    FPath: string;
    FCaption: string;
    public
      property Caption:string read FCaption write FCaption;
      property Path:string read FPath write FPath;
  end;
  TFCSVToJSON = class(TForm)
    pnl2: TPanel;
    pnl3: TPanel;
    pnl1: TPanel;
    pnl5: TPanel;
    pnl4: TPanel;
    chklstListaCSV: TCheckListBox;
    pnl6: TPanel;
    pnl7: TPanel;
    pnl8: TPanel;
    mmoViewCSV: TMemo;
    mmoViewJSON: TMemo;
    grp1: TGroupBox;
    mmoListaCabecario: TMemo;
    btnConverter: TButton;
    chkAll: TCheckBox;
    grp2: TGroupBox;
    lbl1: TLabel;
    edtOrigem: TEdit;
    edtDestino: TEdit;
    lbl2: TLabel;
    rgIsCabecario: TRadioGroup;
    edtCharSep: TEdit;
    lbl3: TLabel;
    btnPreview: TButton;
    il1: TImageList;
    btnOpenOrigem: TButton;
    btnOpenDestino: TButton;
    btnAtualize: TButton;
    pbPreview: TProgressBar;
    il2: TImageList;
    btnAbout: TButton;
    procedure btnOpenOrigemClick(Sender: TObject);
    procedure btnOpenDestinoClick(Sender: TObject);
    procedure btnAtualizeClick(Sender: TObject);
    procedure chkAllClick(Sender: TObject);
    procedure chklstListaCSVClick(Sender: TObject);
    procedure btnConverterClick(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function openDirectory(pDefaultFolder:string=''): string;
    procedure PreencheListaCSV;
    procedure LoadFile(pItem:TItemLista; pGerar:Boolean=False);
    procedure ConverteJSON(pLines:TStrings);
    function GetFormatType(pValue:string; var pType:TFieldType):string;
    function iFThen(Condition: Boolean; ifTrue, ifFalse: Variant):Variant;
  end;

var
  FCSVToJSON: TFCSVToJSON;

implementation
  uses
    ProgressDialog, System.threading, ABOUT;
{$R *.dfm}

{ TForm4 }

procedure TFCSVToJSON.btnAboutClick(Sender: TObject);
  var
    About:TAboutBox;
begin
   try
     About:=TAboutBox.Create(Self);
     About.ShowModal;
   finally
     About.Free;
   end;
end;

procedure TFCSVToJSON.btnAtualizeClick(Sender: TObject);
begin
  PreencheListaCSV;
end;

procedure TFCSVToJSON.btnConverterClick(Sender: TObject);
var
  ProgDlg:TFProgressDialog;
  FRun : ITask;
begin
try
  if edtDestino.Text = '' then
     raise Exception.Create('Path de Destino não informado!');

  ProgDlg:=TFProgressDialog.Create(Self);
  ProgDlg.lblMSG.Caption := 'Processando dados Aguarde...';

  if chklstListaCSV.Items.Count <= 0 then
     raise Exception.Create('Lista de CSV vazia!');

  FRun := TTask.Create(
    procedure
    var
    Lines:TStrings;
    I:Integer;
    begin
      for I := 0 to chklstListaCSV.Items.Count -1 do
      begin
          if not chklstListaCSV.Checked[i] then
              continue;
          chklstListaCSV.ItemIndex := I;
          LoadFile(TItemLista(chklstListaCSV.Items.Objects[i]), True);
          
      end;
      ProgDlg.Close;
    end);

  FRun.Start;
  ProgDlg.ShowModal;
except
  on E:Exception do
    ShowMessage(E.Message);

end;
end;

procedure TFCSVToJSON.btnOpenDestinoClick(Sender: TObject);
begin
  edtDestino.Text := openDirectory(edtDestino.Text);

end;

procedure TFCSVToJSON.btnOpenOrigemClick(Sender: TObject);
begin
  edtOrigem.Text := openDirectory(edtOrigem.Text);
  PreencheListaCSV;
end;

procedure TFCSVToJSON.btnPreviewClick(Sender: TObject);
var
  ProgDlg:TFProgressDialog;
  FRun : ITask;
begin
try
  if mmoViewCSV.Lines.Count <= 0 then
     raise Exception.Create('Sem dados Para visualizar!');
  ProgDlg:=TFProgressDialog.Create(Self);
  ProgDlg.lblMSG.Caption := 'Processando dados Aguarde...';
  FRun := TTask.Create(
    procedure
    var
    Lines:TStrings;
    TS:TStream;
    begin
      try
          Lines := TStringList.Create;
          ConverteJSON(Lines);
          TS := TMemoryStream.Create;
          Lines.SaveToStream(TS);
          Ts.Position := 0;
          mmoViewJSON.Lines.LoadFromStream(TS);
          ProgDlg.Close;

      finally
        Lines.Free;
        TS.Free;
      end;
    end);
  FRun.Start;
  ProgDlg.ShowModal;
except
  on E:Exception do
    ShowMessage(E.Message);
end;

end;

procedure TFCSVToJSON.chkAllClick(Sender: TObject);
var
  I:Integer;
begin
  for I := 0 to chklstListaCSV.Items.Count -1 do
     chklstListaCSV.Checked[I] := chkAll.Checked;
end;

procedure TFCSVToJSON.chklstListaCSVClick(Sender: TObject);
begin

  LoadFile(TItemLista(chklstListaCSV.Items.Objects[chklstListaCSV.ItemIndex]));
end;

procedure TFCSVToJSON.ConverteJSON(pLines:TStrings);
var
  I, J, C:Integer;
  RowItem:TArray<string>;
  Separetor:string;
  LenFied:Integer;
  CSV, Cabecario:Tstrings;
  TyArr:TArray<TFieldType>;
begin
  try
    CSV := TStringList.Create;
    Cabecario:=TStringList.Create;

    TThread.Synchronize(nil, procedure
    var
    TS:TMemoryStream;
    vTemp:string;
    A:Integer;
    begin
      Separetor := edtCharSep.Text;
      if rgIsCabecario.ItemIndex = 0 then
      begin
        LenFied := Length(mmoViewCSV.Lines[I].Split(Separetor));
        mmoListaCabecario.Lines.Clear;
        A := 0;
        while A < LenFied do
        begin
          vTemp := InputBox('Cabeçário CSV', Format('Digite o nome de cabeçário da posição [%d]:',[A]),'chave');
          if vTemp.IndexOf(Separetor) >= 0 then
              if Length(vTemp.Split(Separetor)) <= (LenFied - A) then
              begin
                  A := A + Length(vTemp.Split(Separetor));
                  mmoListaCabecario.Lines.AddStrings(vTemp.Split(Separetor));
                  continue;
              end
              else
              begin
                ShowMessage('Quantidade de campos informados ultrapassa a aquantidade de colunas!');
                continue;
              end;
          mmoListaCabecario.Lines.Add(vTemp);
          Inc(A,1);
        end;
      end;
      try
        TS:=TMemoryStream.Create;

        mmoViewCSV.Lines.SaveToStream(TS);
        TS.Position := 0;
        CSV.LoadFromStream(TS);
        TS.Clear;

        mmoListaCabecario.Lines.SaveToStream(TS);
        TS.Position := 0;
        Cabecario.LoadFromStream(TS);

      finally
        TS.Free;
      end;

    end);

    TThread.Synchronize(nil, procedure
    begin
      pbPreview.Max := CSV.Count -1;
      pbPreview.Position := 0;
    end);
    SetLength(TyArr, Cabecario.Count);
    pLines.Add('[');
    for I := 1 to CSV.Count -1 do
    begin
      TThread.Synchronize(nil, procedure
      begin
        pbPreview.Position := I;
      end);

       pLines.Add('  {');
      RowItem := CSV[I].Split(Separetor);
      if Cabecario.Count <> Length(RowItem) then
          SetLength(RowItem,Cabecario.Count);
      for J := 0 to Cabecario.Count -1 do
      begin
         pLines.Add(Format('   "%s" : %s%s ',[Cabecario[j], GetFormatType(RowItem[J], TyArr[J]),
         ifthen((Cabecario.Count -1) = J, '',',')]));
      end;
       pLines.Add(Format('  }%s',[ ifthen((CSV.Count -1) = I, '',',')]));
    end;
     pLines.Add(']');

  finally
    CSV.Free;
    Cabecario.Free;
  end;
end;

function TFCSVToJSON.GetFormatType(pValue: string; var pType:TFieldType): string;
var
  N:Extended;
  T:TDateTime;
  D:TDate;
begin

try
   pValue := pValue.Trim.Replace('"','');
   if ((pValue.ToUpper = 'NULO') or (pValue.ToUpper = 'NULL')) then
      Exit('null');
   FormatSettings.DecimalSeparator := '.';
   Result := Format('"%s"',[pValue]);
   case pType of
      ftCardial:begin
                  if TryStrToFloat(pValue.Replace(',','.'), N) then
                    Exit(N.ToString)
                  else
                    Exit('null');
                end;
      ftString:Exit;
      ftDateTime:begin
                  if TryStrToDateTime(pValue, T) then
                    Exit(Format('"%s"',[DateTimeToStr(T).Replace('/','\/')]))
                  else
                    Exit('null');
                 end;
   end;

   if TRegEx.IsMatch(pValue, '^0[0-9][^(\/)].*$') then
   begin
      pType := ftString;
      Exit;
   end;

   if TryStrToFloat(pValue.Replace(',','.'), N) then
   begin
      pType := ftCardial;
      Exit(N.ToString);
   end;

   if TryStrToDateTime(pValue, T) then
   begin
     pType := ftDateTime;
     Exit(Format('"%s"',[DateTimeToStr(T).Replace('/','\/')]));
   end;

   pType := ftString;
finally
   FormatSettings.DecimalSeparator := ',';
end;

//  try
//   FormatSettings.DecimalSeparator := '.';
//   Result := Format('"%s"',[pValue]);
//   if TRegEx.IsMatch(pValue, '^\s*[-+]?[0-9]*\.?[0-9]+\s*$') then
//      if TRegEx.IsMatch(pValue, '^[1-9]*|^0$|^0\.') then
//          if TryStrToFloat(pValue, N) then
//                Result := N.ToString;
//  except
//   Result := Format('"%s"',[pValue]);
//  end;
end;

function TFCSVToJSON.iFThen(Condition: Boolean; ifTrue, ifFalse: Variant): Variant;
begin
  if Condition then
     Result := ifTrue
  else
     Result := ifFalse;
end;

procedure TFCSVToJSON.LoadFile(pItem: TItemLista; pGerar: Boolean);
var
  Separetor:string;
  FileJSON:TStrings;
begin
  Separetor := edtCharSep.Text;
  mmoViewCSV.Lines.Clear;
  mmoViewCSV.Lines.LoadFromFile(pItem.Path);
  mmoViewCSV.ScrollBy(0,0);
  mmoListaCabecario.Lines.Clear;
  mmoListaCabecario.Lines.AddStrings(mmoViewCSV.Lines[0].Split(Separetor));
  if pGerar then
  begin
     try
       FileJSON := TStringList.Create;
       ConverteJSON(FileJSON);
       FileJSON.SaveToFile(Format('%s%s',[edtDestino.Text, pItem.Caption.Replace('.csv','.json')]),TEncoding.UTF8);
     finally
       FileJSON.Free;
     end;
  end;

end;

function TFCSVToJSON.openDirectory(pDefaultFolder: string): string;
begin
  Result := '';
    with TFileOpenDialog.Create(nil) do
    try
      if(pDefaultFolder <> '') then
        DefaultFolder:= pDefaultFolder;
      Options := [fdoPickFolders];
      if Execute then
        Result := FileName +'\';
    finally
      Free;
    end;
end;

procedure TFCSVToJSON.PreencheListaCSV;
var
  SR      : TSearchRec;
  Item    : TItemLista;
  Idx     : Integer;
begin
  if edtOrigem.Text = '' then
    raise Exception.Create('Sem diretório de destino!');
  chklstListaCSV.Items.Clear;
  if FindFirst(edtOrigem.Text + '*.csv', faArchive, SR) = 0 then
  begin
    repeat
        Item := TItemLista.Create;
        Item.Caption := SR.Name;
        Item.Path    := Format('%s%s',[edtOrigem.Text, SR.Name]);
        Idx := chklstListaCSV.Items.AddObject(Item.Caption, Item); //Fill the list
        chklstListaCSV.Checked[Idx] := chkAll.Checked;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

end.
