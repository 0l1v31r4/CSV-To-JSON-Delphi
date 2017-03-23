program CSVToJSON;

uses
  Vcl.Forms,
  Principal in 'Principal.pas' {FCSVToJSON},
  ProgressDialog in 'ProgressDialog.pas' {FProgressDialog};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFCSVToJSON, FCSVToJSON);
  Application.Run;
end.
