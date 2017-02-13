unit BCEditor.Highlighter;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Graphics, BCEditor.Highlighter.Rules, BCEditor.Highlighter.Token,
  BCEditor.Consts, BCEditor.Highlighter.Attributes, BCEditor.Highlighter.Info, BCEditor.Editor.SkipRegions,
  BCEditor.Highlighter.Colors, BCEditor.Editor.CodeFolding.Regions, BCEditor.Highlighter.Comments, BCEditor.Types;

type
  TBCEditorHighlighter = class(TObject)
  strict private
    FAllDelimiters: TBCEditorCharSet;
    FAttributes: TStringList;
    FBeginningOfLine: Boolean;
    FCodeFoldingRangeCount: Integer;
    FCodeFoldingRegions: TBCEditorCodeFoldingRegions;
    FColors: TBCEditorHighlighterColors;
    FComments: TBCEditorHighlighterComments;
    FCompletionProposalSkipRegions: TBCEditorSkipRegions;
    FCurrentLine: PChar;
    FCurrentRange: TBCEditorRange;
    FCurrentToken: TBCEditorToken;
    FEditor: TWinControl;
    FEndOfLine: Boolean;
    FFileName: string;
    FFoldCloseKeyChars: TBCEditorCharSet;
    FFoldOpenKeyChars: TBCEditorCharSet;
    FInfo: TBCEditorHighlighterInfo;
    FLoading: Boolean;
    FMainRules: TBCEditorRange;
    FMatchingPairHighlight: Boolean;
    FMatchingPairs: TList;
    FMultiHighlighter: Boolean;
    FName: string;
    FPreviousEndOfLine: Boolean;
    FRunPosition: LongInt;
    FSkipCloseKeyChars: TBCEditorCharSet;
    FSkipOpenKeyChars: TBCEditorCharSet;
    FTemporaryCurrentTokens: TList;
    FTokenPosition: Integer;
    FWordBreakChars: TBCEditorCharSet;
    procedure AddAllAttributes(ARange: TBCEditorRange);
    procedure UpdateAttributes(ARange: TBCEditorRange; AParentRange: TBCEditorRange);
  protected
    function GetAttribute(AIndex: Integer): TBCEditorHighlighterAttribute;
    procedure AddAttribute(AHighlighterAttribute: TBCEditorHighlighterAttribute);
    procedure Prepare;
    procedure Reset;
    procedure SetAttributesOnChange(AEvent: TNotifyEvent);
    procedure SetCodeFoldingRangeCount(AValue: Integer);
    procedure SetWordBreakChars(AChars: TBCEditorCharSet);
  public
    constructor Create(AOwner: TWinControl);
    destructor Destroy; override;

    function GetCurrentRange: TBCEditorRange;
    function GetCurrentRangeAttribute: TBCEditorHighlighterAttribute;
    function GetEndOfLine: Boolean;
    function GetTokenAttribute: TBCEditorHighlighterAttribute;
    function GetTokenKind: TBCEditorRangeType;
    function GetTokenLength: Integer;
    function GetTokenPosition: Integer;
    procedure AddKeyChar(AKeyCharType: TBCEditorKeyCharType; AChar: Char);
    procedure AddKeywords(var AStringList: TStringList);
    procedure Clear;
    procedure GetToken(var AResult: string);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(AStream: TStream);
    procedure Next;
    procedure NextToEndOfLine;
    procedure ResetCurrentRange;
    procedure SetCurrentLine(const ANewValue: string);
    procedure SetCurrentRange(AValue: Pointer);
    procedure UpdateColors;
    property Attribute[AIndex: Integer]: TBCEditorHighlighterAttribute read GetAttribute;
    property Attributes: TStringList read FAttributes;
    property CodeFoldingRangeCount: Integer read FCodeFoldingRangeCount write SetCodeFoldingRangeCount;
    property CodeFoldingRegions: TBCEditorCodeFoldingRegions read FCodeFoldingRegions write FCodeFoldingRegions;
    property Colors: TBCEditorHighlighterColors read FColors write FColors;
    property Comments: TBCEditorHighlighterComments read FComments write FComments;
    property CompletionProposalSkipRegions: TBCEditorSkipRegions read FCompletionProposalSkipRegions write FCompletionProposalSkipRegions;
    property Editor: TWinControl read FEditor;
    property FileName: string read FFileName write FFileName;
    property FoldCloseKeyChars: TBCEditorCharSet read FFoldCloseKeyChars write FFoldCloseKeyChars;
    property FoldOpenKeyChars: TBCEditorCharSet read FFoldOpenKeyChars write FFoldOpenKeyChars;
    property Info: TBCEditorHighlighterInfo read FInfo write FInfo;
    property Loading: Boolean read FLoading write FLoading;
    property MainRules: TBCEditorRange read FMainRules;
    property MatchingPairHighlight: Boolean read FMatchingPairHighlight write FMatchingPairHighlight default True;
    property MatchingPairs: TList read FMatchingPairs write FMatchingPairs;
    property MultiHighlighter: Boolean read FMultiHighlighter write FMultiHighlighter;
    property Name: string read FName write FName;
    property SkipCloseKeyChars: TBCEditorCharSet read FSkipCloseKeyChars write FSkipCloseKeyChars;
    property SkipOpenKeyChars: TBCEditorCharSet read FSkipOpenKeyChars write FSkipOpenKeyChars;
    property WordBreakChars: TBCEditorCharSet read FWordBreakChars write SetWordBreakChars;
  end;

implementation

uses
  BCEditor.Highlighter.Import.JSON, System.Types, BCEditor.Editor.Base, System.IOUtils;

procedure TBCEditorHighlighter.AddKeyChar(AKeyCharType: TBCEditorKeyCharType; AChar: Char);
begin
  case AKeyCharType of
    ctFoldOpen: FFoldOpenKeyChars := FFoldOpenKeyChars + [AChar];
    ctFoldClose: FFoldCloseKeyChars := FFoldCloseKeyChars + [AChar];
    ctSkipOpen: FSkipOpenKeyChars := FSkipOpenKeyChars + [AChar];
    ctSkipClose: FSkipCloseKeyChars := FSkipCloseKeyChars + [AChar];
  end;
end;

constructor TBCEditorHighlighter.Create(AOwner: TWinControl);
begin
  inherited Create;

  FEditor := AOwner;
  FWordBreakChars := BCEDITOR_WORD_BREAK_CHARACTERS;

  FAttributes := TStringList.Create;
  FAttributes.Duplicates := dupIgnore;
  FAttributes.Sorted := False;

  FCodeFoldingRangeCount := 0;

  FComments := TBCEditorHighlighterComments.Create;

  FCompletionProposalSkipRegions := TBCEditorSkipRegions.Create(TBCEditorSkipRegionItem);

  Info := TBCEditorHighlighterInfo.Create;
  FMainRules := TBCEditorRange.Create;
  FMainRules.Parent := FMainRules;

  FEndOfLine := False;
  FBeginningOfLine := True;
  FPreviousEndOfLine := False;
  FCurrentRange := MainRules;

  FColors := TBCEditorHighlighterColors.Create(Self);
  FMatchingPairs := TList.Create;
  FMatchingPairHighlight := True;

  FTemporaryCurrentTokens := TList.Create;

  FAllDelimiters := BCEDITOR_DEFAULT_DELIMITERS + BCEDITOR_ABSOLUTE_DELIMITERS;

  FLoading := False;
end;

destructor TBCEditorHighlighter.Destroy;
begin
  Clear;

  FComments.Free;
  FComments := nil;
  FMainRules.Free;
  FMainRules := nil;
  FInfo.Free;
  FInfo := nil;
  FAttributes.Free;
  FAttributes := nil;
  FCompletionProposalSkipRegions.Free;
  FCompletionProposalSkipRegions := nil;
  FMatchingPairs.Free;
  FMatchingPairs := nil;
  FColors.Free;
  FColors := nil;
  FTemporaryCurrentTokens.Free;

  inherited;
end;

procedure TBCEditorHighlighter.AddAllAttributes(ARange: TBCEditorRange);
var
  LIndex: Integer;
begin
  AddAttribute(ARange.Attribute);
  for LIndex := 0 to ARange.KeyListCount - 1 do
    AddAttribute(ARange.KeyList[LIndex].Attribute);
  for LIndex := 0 to ARange.SetCount - 1 do
    AddAttribute(ARange.Sets[LIndex].Attribute);
  for LIndex := 0 to ARange.RangeCount - 1 do
    AddAllAttributes(ARange.Ranges[LIndex]);
end;

procedure TBCEditorHighlighter.SetCurrentLine(const ANewValue: string);
begin
  if Assigned(FCurrentRange) then
    if not FCurrentRange.Prepared then
      Prepare;

  FCurrentLine := PChar(ANewValue);
  FRunPosition := 0;
  FTokenPosition := 0;
  FEndOfLine := False;
  FBeginningOfLine := True;
  FPreviousEndOfLine := False;
  FCurrentToken := nil;
  Next;
end;

procedure TBCEditorHighlighter.Next;
var
  LIndex, LPosition: Integer;
  LParser: TBCEditorAbstractParser;
  LKeyword: PChar;
  LCloseParent: Boolean;
  LDelimiters: TBCEditorCharSet;
begin
  while FTemporaryCurrentTokens.Count > 0 do
  begin
    FCurrentToken := TBCEditorToken(FTemporaryCurrentTokens[0]);
    FCurrentToken.Free;
    FCurrentToken := nil;
    FTemporaryCurrentTokens.Delete(0);
  end;

  if FPreviousEndOfLine then
  begin
    if Assigned(FCurrentRange) then
      if FCurrentRange.CloseOnEndOfLine or FCurrentRange.CloseOnTerm then
        FCurrentRange := FCurrentRange.Parent;
    FEndOfLine := True;
    Exit;
  end;

  if Assigned(FCurrentRange) then
    if FCurrentRange.AlternativeCloseArrayCount > 0 then
      for LIndex := 0 to FCurrentRange.AlternativeCloseArrayCount - 1 do
      begin
        LKeyword := PChar(FCurrentRange.AlternativeCloseArray[LIndex]);
        LPosition := FRunPosition;
        while (FCurrentLine[LPosition] <> BCEDITOR_NONE_CHAR) and (FCurrentLine[LPosition] = LKeyword^) do
        begin
          Inc(LKeyword);
          Inc(LPosition);
        end;
        if LKeyword^ = BCEDITOR_NONE_CHAR then
        begin
          FCurrentRange := FCurrentRange.Parent;
          Break;
        end;
      end;

  FTokenPosition := FRunPosition;

  if Assigned(FCurrentRange) then
  begin
    LCloseParent := FCurrentRange.CloseParent;
    if FCurrentRange.CloseOnTerm and CharInSet(FCurrentLine[FRunPosition], FCurrentRange.Delimiters) and
      not (FCurrentRange.SkipWhitespace and CharInSet(FCurrentLine[FRunPosition], BCEDITOR_ABSOLUTE_DELIMITERS)) then
    begin
      FCurrentRange := FCurrentRange.Parent;
      if Assigned(FCurrentRange) then
        if LCloseParent then
          FCurrentRange := FCurrentRange.Parent;
    end;

    if Ord(FCurrentLine[FRunPosition]) < 256 then
      LParser := FCurrentRange.SymbolList[AnsiChar(FCurrentRange.CaseFunct(FCurrentLine[FRunPosition]))]
    else
      LParser := FCurrentRange.SymbolList['a'];

    if not Assigned(LParser) then
      Inc(FRunPosition)
    else
    if not LParser.GetToken(FCurrentRange, FCurrentLine, FRunPosition, FCurrentToken) then
    begin
      FCurrentToken := FCurrentRange.DefaultToken;

      if FCurrentRange.UseDelimitersForText then
        LDelimiters := FCurrentRange.Delimiters
      else
        LDelimiters := FAllDelimiters;

      if Ord(FCurrentLine[FRunPosition - 1]) < 256 then
      while (Ord(FCurrentLine[FRunPosition]) < 256) and not CharInSet(FCurrentLine[FRunPosition], LDelimiters) do
        Inc(FRunPosition)
      else
      while (Ord(FCurrentLine[FRunPosition]) > 255) and not CharInSet(FCurrentLine[FRunPosition], LDelimiters) do
        Inc(FRunPosition)
    end
    else
    if FCurrentRange.ClosingToken = FCurrentToken then
      FCurrentRange := FCurrentRange.Parent
    else
    if Assigned(FCurrentToken) and Assigned(FCurrentToken.OpenRule) then
      if FCurrentToken.OpenRule is TBCEditorRange then
      begin
        FCurrentRange := TBCEditorRange(FCurrentToken.OpenRule);
        FCurrentRange.ClosingToken := FCurrentToken.ClosingToken;
        if FCurrentRange.OpenBeginningOfLine and not FBeginningOfLine then
        begin
          FCurrentRange := FCurrentRange.Parent;
          FCurrentToken := FCurrentRange.DefaultToken;
        end;
      end;
    if Assigned(FCurrentToken) then
      if FCurrentToken.Temporary then
        FTemporaryCurrentTokens.Add(FCurrentToken);
  end;

  if FBeginningOfLine then
    if FRunPosition >= 1 then
      if not CharInset(FCurrentLine[FRunPosition - 1], BCEDITOR_ABSOLUTE_DELIMITERS) then
        FBeginningOfLine := False;

  if FCurrentLine[FRunPosition] = BCEDITOR_NONE_CHAR then
    FPreviousEndOfLine := True;
end;

function TBCEditorHighlighter.GetCurrentRangeAttribute: TBCEditorHighlighterAttribute;
begin
  Result := nil;
  if Assigned(FCurrentRange) then
    Result := FCurrentRange.Attribute;
end;

function TBCEditorHighlighter.GetEndOfLine: Boolean;
begin
  Result := FEndOfLine;
end;

function TBCEditorHighlighter.GetCurrentRange: TBCEditorRange;
begin
  Result := FCurrentRange;
end;

function TBCEditorHighlighter.GetTokenAttribute: TBCEditorHighlighterAttribute;
begin
  if Assigned(FCurrentToken) then
    Result := FCurrentToken.Attribute
  else
    Result := nil;
end;

function TBCEditorHighlighter.GetTokenPosition: Integer;
begin
  Result := FTokenPosition;
end;

procedure TBCEditorHighlighter.ResetCurrentRange;
begin
  FCurrentRange := MainRules;
end;

procedure TBCEditorHighlighter.SetCodeFoldingRangeCount(AValue: Integer);
begin
  if FCodeFoldingRangeCount <> AValue then
  begin
    SetLength(FCodeFoldingRegions, AValue);
    FCodeFoldingRangeCount := AValue;
  end;
end;

procedure TBCEditorHighlighter.SetCurrentRange(AValue: Pointer);
begin
  FCurrentRange := TBCEditorRange(AValue);
end;

procedure TBCEditorHighlighter.AddKeywords(var AStringList: TStringList);
var
  LIndex, LIndex2: Integer;
begin
  if not Assigned(AStringList) then
    Exit;
  for LIndex := 0 to FMainRules.KeyListCount - 1 do
    for LIndex2 := 0 to FMainRules.KeyList[LIndex].KeyList.Count - 1 do
      AStringList.Add(FMainRules.KeyList[LIndex].KeyList[LIndex2]);
end;

procedure TBCEditorHighlighter.GetToken(var AResult: string);
var
  LLength: LongInt;
begin
  LLength := FRunPosition - FTokenPosition;
  SetString(AResult, FCurrentLine + FTokenPosition, LLength);
end;

procedure TBCEditorHighlighter.Reset;
begin
  MainRules.Reset;
end;

function TBCEditorHighlighter.GetTokenKind: TBCEditorRangeType;
var
  LIndex: Integer;
  LToken: string;
  LTokenType: TBCEditorRangeType;
  LCurrentRangeKeyList: TBCEditorKeyList;
begin
  LTokenType := FCurrentRange.TokenType;
  if LTokenType <> ttUnspecified then
    Result := LTokenType
  else
  { keyword token type }
  begin
    GetToken(LToken);
    for LIndex := 0 to FCurrentRange.KeyListCount - 1 do
    begin
      LCurrentRangeKeyList := FCurrentRange.KeyList[LIndex];
      if LCurrentRangeKeyList.KeyList.IndexOf(LToken) <> -1 then
        Exit(LCurrentRangeKeyList.TokenType);
    end;
    Result := ttUnspecified
  end;
end;

procedure TBCEditorHighlighter.Clear;
var
  LIndex: Integer;
begin
  FFoldOpenKeyChars := [];
  FFoldCloseKeyChars := [];
  FSkipOpenKeyChars := [];
  FSkipCloseKeyChars := [];
  FAttributes.Clear;
  FMainRules.Clear;
  FInfo.Clear;
  FComments.Clear;
  FCompletionProposalSkipRegions.Clear;
  for LIndex := FMatchingPairs.Count - 1 downto 0 do
    Dispose(PBCEditorMatchingPairToken(FMatchingPairs.Items[LIndex]));
  FMatchingPairs.Clear;
  for LIndex := 0 to FCodeFoldingRangeCount - 1 do
  begin
    FCodeFoldingRegions[LIndex].Free;
    FCodeFoldingRegions[LIndex] := nil;
  end;
  CodeFoldingRangeCount := 0;
  (Editor as TBCBaseEditor).ClearMatchingPair;
end;

procedure TBCEditorHighlighter.Prepare;
begin
  FAttributes.Clear;
  AddAllAttributes(MainRules);
  FMainRules.Prepare(FMainRules);
end;

procedure TBCEditorHighlighter.UpdateAttributes(ARange: TBCEditorRange; AParentRange: TBCEditorRange);
var
  LIndex: Integer;

  procedure SetAttributes(AAttribute: TBCEditorHighlighterAttribute; AParentRange: TBCEditorRange);
  var
    LElement: PBCEditorHighlighterElement;
  begin
    LElement := FColors.GetElement(AAttribute.Element);

    if AAttribute.ParentBackground and Assigned(AParentRange) then
      AAttribute.Background := AParentRange.Attribute.Background
    else
    if Assigned(LElement) then
      AAttribute.Background := LElement.Background;
    if AAttribute.ParentForeground and Assigned(AParentRange) then
      AAttribute.Foreground := AParentRange.Attribute.Foreground
    else
    if Assigned(LElement) then
      AAttribute.Foreground := LElement.Foreground;
    if Assigned(LElement) then
      AAttribute.FontStyles := LElement.FontStyles;
  end;

begin
  SetAttributes(ARange.Attribute, AParentRange);

  for LIndex := 0 to ARange.KeyListCount - 1 do
    SetAttributes(ARange.KeyList[LIndex].Attribute, ARange);
  for LIndex := 0 to ARange.SetCount - 1 do
    SetAttributes(ARange.Sets[LIndex].Attribute, ARange);

  if ARange.RangeCount > 0 then
  for LIndex := 0 to ARange.RangeCount - 1 do
    UpdateAttributes(ARange.Ranges[LIndex], ARange);
end;

procedure TBCEditorHighlighter.UpdateColors;
var
  LEditor: TBCBaseEditor;
  LFontDummy: TFont;
begin
  UpdateAttributes(MainRules, nil);
  LEditor := FEditor as TBCBaseEditor;
  if Assigned(LEditor) then
  begin
    LFontDummy := TFont.Create;
    try
      LFontDummy.Name := LEditor.Font.Name;
      LFontDummy.Size := LEditor.Font.Size;
      LEditor.Font.Assign(LFontDummy);
    finally
      LFontDummy.Free;
    end;
  end;
end;

procedure TBCEditorHighlighter.LoadFromFile(const AFileName: string);
var
  LStream: TStream;
  LEditor: TBCBaseEditor;
begin
  FFileName := AFileName;
  FName := TPath.GetFileNameWithoutExtension(AFileName);
  LEditor := FEditor as TBCBaseEditor;
  if Assigned(LEditor) then
  begin
    LStream := LEditor.CreateFileStream(LEditor.GetHighlighterFileName(AFileName));
    try
      LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

procedure TBCEditorHighlighter.LoadFromStream(AStream: TStream);
var
  LEditor: TBCBaseEditor;
  LTempLines: TStringList;
  LTopLine: Integer;
  LCaretPosition: TBCEditorTextPosition;
begin
  Clear;
  LEditor := FEditor as TBCBaseEditor;
  if Assigned(LEditor) then
  begin
    FLoading := True;
    LTempLines := TStringList.Create;
    try
      if LEditor.Visible then
        LCaretPosition := LEditor.TextCaretPosition;
      LTopLine := LEditor.TopLine;
      LTempLines.AddStrings(LEditor.Lines);
      LEditor.Lines.Clear;
      with TBCEditorHighlighterImportJSON.Create(Self) do
      try
        ImportFromStream(AStream);
      finally
        Free;
      end;
      LEditor.Lines.LoadFromStrings(LTempLines);
      LEditor.TopLine := LTopLine;
      if LEditor.Visible then
        LEditor.TextCaretPosition := LCaretPosition;
    finally
      LTempLines.Free;
    end;
    UpdateColors;
    FLoading := False;
  end;
end;

function TBCEditorHighlighter.GetAttribute(AIndex: Integer): TBCEditorHighlighterAttribute;
begin
  Result := nil;
  if (AIndex >= 0) and (AIndex < FAttributes.Count) then
    Result := TBCEditorHighlighterAttribute(FAttributes.Objects[AIndex]);
end;

procedure TBCEditorHighlighter.AddAttribute(AHighlighterAttribute: TBCEditorHighlighterAttribute);
begin
  FAttributes.AddObject(AHighlighterAttribute.Name, AHighlighterAttribute);
end;

procedure TBCEditorHighlighter.SetWordBreakChars(AChars: TBCEditorCharSet);
begin
  FWordBreakChars := AChars;
end;

procedure TBCEditorHighlighter.NextToEndOfLine;
begin
  while not GetEndOfLine do
    Next;
end;

procedure TBCEditorHighlighter.SetAttributesOnChange(AEvent: TNotifyEvent);
var
  LIndex: Integer;
  LHighlighterAttribute: TBCEditorHighlighterAttribute;
begin
  for LIndex := FAttributes.Count - 1 downto 0 do
  begin
    LHighlighterAttribute := TBCEditorHighlighterAttribute(FAttributes.Objects[LIndex]);
    if Assigned(LHighlighterAttribute) then
    begin
      LHighlighterAttribute.OnChange := AEvent;
      LHighlighterAttribute.InternalSaveDefaultValues;
    end;
  end;
end;

function TBCEditorHighlighter.GetTokenLength: Integer;
begin
  Result := FRunPosition - FTokenPosition;
end;

end.

