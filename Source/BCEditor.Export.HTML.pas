unit BCEditor.Export.HTML;

interface

uses
  System.Classes, System.SysUtils, BCEditor.Lines, BCEditor.Highlighter;

type
  TBCEditorExportHTML = class(TObject)
  private
    FCharSet: string;
    FHighlighter: TBCEditorHighlighter;
    FLines: TBCEditorLines;
    FStringList: TStrings;
    procedure CreateHTMLDocument;
    procedure CreateHeader;
    procedure CreateInternalCSS;
    procedure CreateLines;
    procedure CreateFooter;
  public
    constructor Create(ALines: TBCEditorLines; AHighlighter: TBCEditorHighlighter; ACharSet: string); overload;
    destructor Destroy; override;

    procedure SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
  end;

implementation

uses
  System.UITypes, System.Math, BCEditor.Highlighter.Attributes, BCEditor.Highlighter.Colors;

constructor TBCEditorExportHTML.Create(ALines: TBCEditorLines; AHighlighter: TBCEditorHighlighter; ACharSet: string);
begin
  inherited Create;

  FStringList := TStringList.Create;

  FCharSet := ACharSet;
  if FCharSet = '' then
    FCharSet := 'utf-8';
  FLines := ALines;
  FHighlighter := AHighlighter;
end;

destructor TBCEditorExportHTML.Destroy;
begin
  FStringList.Free;

  inherited Destroy;
end;

procedure TBCEditorExportHTML.CreateHTMLDocument;
begin
  if not Assigned(FHighlighter) then
    Exit;
  if FLines.Count = 0 then
    Exit;

  CreateHeader;
  CreateLines;
  CreateFooter;
end;

procedure TBCEditorExportHTML.CreateHeader;
begin
  FStringList.Add('<!DOCTYPE HTML>');
  FStringList.Add('');
  FStringList.Add('<html>');
  FStringList.Add('<head>');
	FStringList.Add('  <meta charset="' + FCharSet + '">');

  CreateInternalCSS;

  FStringList.Add('</head>');
  FStringList.Add('');
  FStringList.Add('<body>');
end;

procedure TBCEditorExportHTML.CreateInternalCSS;
var
  i: Integer;
  LStyles: TList;
  LElement: PBCEditorHighlighterElement;
begin
  FStringList.Add('  <style>');

  LStyles := FHighlighter.Colors.Styles;

  for i := 0 to LStyles.Count - 1 do
  begin
    LElement := LStyles.Items[i];

    FStringList.Add('    ' + LElement^.Name + ' { ');
    FStringList.Add('      color: #' + IntToHex(LElement^.Foreground, 6) + ';');
    FStringList.Add('      background-color: #' + IntToHex(LElement^.Background, 6) + ';');

    if TFontStyle.fsBold in LElement^.Style then
      FStringList.Add('      font-weight: bold;');

    if TFontStyle.fsItalic in LElement^.Style then
      FStringList.Add('      font-style: italic;');

    if TFontStyle.fsUnderline in LElement^.Style then
      FStringList.Add('      text-decoration: underline;');

    if TFontStyle.fsStrikeOut in LElement^.Style then
      FStringList.Add('      text-decoration: line-through;');

    FStringList.Add('    }');
  end;
  FStringList.Add('  </style>');
end;

procedure TBCEditorExportHTML.CreateLines;
var
  i: Integer;
  LHighlighterAttribute: TBCEditorHighlighterAttribute;
begin
  for i := 0 to FLines.Count - 1 do
  begin
    if i = 0 then
      FHighlighter.ResetCurrentRange
    else
      FHighlighter.SetCurrentRange(FLines.Ranges[i]);
    FHighlighter.SetCurrentLine(FLines[i]);
    while not FHighlighter.GetEndOfLine do
    begin
      LHighlighterAttribute := FHighlighter.GetTokenAttribute;


      FHighlighter.Next;
    end;
  end;
end;

{
&	&amp;
<	&lt;
>	&gt;
"	&quot;}

procedure TBCEditorExportHTML.CreateFooter;
begin
  FStringList.Add('</body>');
  FStringList.Add('</html>');
end;

procedure TBCEditorExportHTML.SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
begin
  CreateHTMLDocument;
  if not Assigned(AEncoding) then
    AEncoding := TEncoding.UTF8;
  FStringList.SaveToStream(AStream, AEncoding);
end;

end.
