program CSVToJSON;

uses
  Vcl.Forms,
  Principal in 'src\telas\Principal.pas' {FCSVToJSON},
  ProgressDialog in 'src\telas\ProgressDialog.pas' {FProgressDialog};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFCSVToJSON, FCSVToJSON);
  Application.Run;
end.
