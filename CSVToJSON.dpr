program CSVToJSON;

uses
  Vcl.Forms,
  Principal in 'src\telas\Principal.pas' {FCSVToJSON},
  ProgressDialog in 'src\telas\ProgressDialog.pas' {FProgressDialog},
  ABOUT in 'src\telas\ABOUT.pas' {AboutBox};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFCSVToJSON, FCSVToJSON);
  Application.Run;
end.
