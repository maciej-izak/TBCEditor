unit BCEditor.Editor.Replace;

interface

uses
  System.Classes, BCEditor.Types;

type
  TBCEditorReplace = class(TPersistent)
  strict private
    FAction: TBCEditorReplaceActionOption;
    FEngine: TBCEditorSearchEngine;
    FOnChange: TBCEditorReplaceChangeEvent;
    FOptions: TBCEditorReplaceOptions;
    procedure SetEngine(const AValue: TBCEditorSearchEngine);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TBCEditorReplaceOption; const AEnabled: Boolean);
  published
    property Action: TBCEditorReplaceActionOption read FAction write FAction default eraReplace;
    property Engine: TBCEditorSearchEngine read FEngine write SetEngine default seNormal;
    property OnChange: TBCEditorReplaceChangeEvent read FOnChange write FOnChange;
    property Options: TBCEditorReplaceOptions read FOptions write FOptions default [roPrompt];
  end;

implementation

constructor TBCEditorReplace.Create;
begin
  inherited;

  FAction := eraReplace;
  FEngine := seNormal;
  FOptions := [roPrompt];
end;

procedure TBCEditorReplace.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TBCEditorReplace) then
  with ASource as TBCEditorReplace do
  begin
    Self.FEngine := Engine;
    Self.FOptions := Options;
    Self.FAction := Action;
  end
  else
    inherited Assign(ASource);
end;

procedure TBCEditorReplace.SetOption(const AOption: TBCEditorReplaceOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TBCEditorReplace.SetEngine(const AValue: TBCEditorSearchEngine);
begin
  if FEngine <> AValue then
  begin
    FEngine := AValue;
    if Assigned(FOnChange) then
      FOnChange(rcEngineUpdate);
  end;
end;

end.
