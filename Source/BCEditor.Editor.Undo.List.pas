unit BCEditor.Editor.Undo.List;

interface

uses
  System.Classes, BCEditor.Editor.Undo.Item, BCEditor.Types, BCEditor.Consts;

type
  TBCEditorUndoList = class(TPersistent)
  protected
    FBlockCount: Integer;
    FBlockNumber: Integer;
    FChangeBlockNumber: Integer;
    FChanged: Boolean;
    FChangeCount: Integer;
    FInsideRedo: Boolean;
    FInsideUndoBlock: Boolean;
    FInsideUndoBlockCount: Integer;
    FItems: TList;
    FLockCount: Integer;
    FOnAddedUndo: TNotifyEvent;
    function GetCanUndo: Boolean;
    function GetItemCount: Integer;
    function GetItems(const AIndex: Integer): TBCEditorUndoItem;
    procedure SetItems(const AIndex: Integer; const AValue: TBCEditorUndoItem);
  public
    constructor Create;
    destructor Destroy; override;

    function PeekItem: TBCEditorUndoItem;
    function PopItem: TBCEditorUndoItem;
    function LastChangeBlockNumber: Integer;
    function LastChangeReason: TBCEditorChangeReason;
    function LastChangeString: string;
    procedure AddChange(AReason: TBCEditorChangeReason;
      const ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition: TBCEditorTextPosition;
      const AChangeText: string; SelectionMode: TBCEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure BeginBlock(AChangeBlockNumber: Integer = 0);
    procedure Clear;
    procedure EndBlock;
    procedure Lock;
    procedure PushItem(AItem: TBCEditorUndoItem);
    procedure Unlock;
  public
    procedure AddGroupBreak;
    procedure Assign(ASource: TPersistent); override;
    property BlockCount: Integer read FBlockCount;
    property CanUndo: Boolean read GetCanUndo;
    property Changed: Boolean read FChanged write FChanged;
    property ChangeCount: Integer read FChangeCount;
    property InsideRedo: Boolean read FInsideRedo write FInsideRedo default False;
    property InsideUndoBlock: Boolean read FInsideUndoBlock write FInsideUndoBlock default False;
    property ItemCount: Integer read GetItemCount;
    property Items[const AIndex: Integer]: TBCEditorUndoItem read GetItems write SetItems;
    property OnAddedUndo: TNotifyEvent read FOnAddedUndo write FOnAddedUndo;
  end;

implementation

const
  BCEDITOR_MODIFYING_CHANGE_REASONS = [crInsert, crPaste, crDragDropInsert, crDelete, crLineBreak, crIndent, crUnindent];

constructor TBCEditorUndoList.Create;
begin
  inherited;

  FItems := TList.Create;
  FInsideRedo := False;
  FInsideUndoBlock := False;
  FInsideUndoBlockCount := 0;
  FChangeCount := 0;
  FBlockNumber := BCEDITOR_UNDO_BLOCK_NUMBER_START;
end;

destructor TBCEditorUndoList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TBCEditorUndoList.Assign(ASource: TPersistent);
var
  LIndex: Integer;
  LUndoItem: TBCEditorUndoItem;
begin
  if Assigned(ASource) and (ASource is TBCEditorUndoList) then
  with ASource as TBCEditorUndoList do
  begin
    Self.Clear;
    for LIndex := 0 to (ASource as TBCEditorUndoList).FItems.Count - 1 do
    begin
      LUndoItem := TBCEditorUndoItem.Create;
      LUndoItem.Assign(FItems[LIndex]);
      Self.FItems.Add(LUndoItem);
    end;
    Self.FInsideUndoBlock := FInsideUndoBlock;
    Self.FBlockCount := FBlockCount;
    Self.FChangeBlockNumber := FChangeBlockNumber;
    Self.FLockCount := FLockCount;
    Self.FInsideRedo := FInsideRedo;
  end
  else
    inherited Assign(ASource);
end;

procedure TBCEditorUndoList.AddChange(AReason: TBCEditorChangeReason;
  const ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition: TBCEditorTextPosition;
  const AChangeText: string; SelectionMode: TBCEditorSelectionMode; AChangeBlockNumber: Integer = 0);
var
  LNewItem: TBCEditorUndoItem;
begin
  if FLockCount = 0 then
  begin
    FChanged := AReason in BCEDITOR_MODIFYING_CHANGE_REASONS;

    if FChanged then
      Inc(FChangeCount);

    LNewItem := TBCEditorUndoItem.Create;
    with LNewItem do
    begin
      if AChangeBlockNumber <> 0 then
        ChangeBlockNumber := AChangeBlockNumber
      else
      if FInsideUndoBlock then
        ChangeBlockNumber := FChangeBlockNumber
      else
        ChangeBlockNumber := 0;
      ChangeReason := AReason;
      ChangeSelectionMode := SelectionMode;
      ChangeCaretPosition := ACaretPosition;
      ChangeBeginPosition := ASelectionBeginPosition;
      ChangeEndPosition := ASelectionEndPosition;
      ChangeString := AChangeText;
    end;
    PushItem(LNewItem);
  end;
end;

procedure TBCEditorUndoList.BeginBlock(AChangeBlockNumber: Integer = 0);
begin
  Inc(FBlockCount);

  if FInsideUndoBlock then
    Exit;

  if AChangeBlockNumber = 0 then
  begin
    Inc(FBlockNumber);
    FChangeBlockNumber := FBlockNumber;
  end
  else
    FChangeBlockNumber := AChangeBlockNumber;

  FInsideUndoBlockCount := FBlockCount;
  FInsideUndoBlock := True;
end;

procedure TBCEditorUndoList.Clear;
var
  LIndex: Integer;
begin
  FBlockCount := 0;
  for LIndex := 0 to FItems.Count - 1 do
    TBCEditorUndoItem(FItems[LIndex]).Free;
  FItems.Clear;
  FChangeCount := 0;
end;

procedure TBCEditorUndoList.EndBlock;
begin
  Assert(FBlockCount > 0);
  if FInsideUndoBlockCount = FBlockCount then
    FInsideUndoBlock := False;
  Dec(FBlockCount);
end;

function TBCEditorUndoList.GetCanUndo: Boolean;
begin
  Result := FItems.Count > 0;
end;

function TBCEditorUndoList.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TBCEditorUndoList.Lock;
begin
  Inc(FLockCount);
end;

function TBCEditorUndoList.PeekItem: TBCEditorUndoItem;
var
  LIndex: Integer;
begin
  Result := nil;
  LIndex := FItems.Count - 1;
  if LIndex >= 0 then
    Result := FItems[LIndex];
end;

function TBCEditorUndoList.PopItem: TBCEditorUndoItem;
var
  LIndex: Integer;
begin
  Result := nil;
  LIndex := FItems.Count - 1;
  if LIndex >= 0 then
  begin
    Result := FItems[LIndex];
    FItems.Delete(LIndex);
    FChanged := Result.ChangeReason in BCEDITOR_MODIFYING_CHANGE_REASONS;
    if FChanged then
      Dec(FChangeCount);
  end;
end;

procedure TBCEditorUndoList.PushItem(AItem: TBCEditorUndoItem);
begin
  if Assigned(AItem) then
  begin
    FItems.Add(AItem);
    if (AItem.ChangeReason <> crGroupBreak) and Assigned(OnAddedUndo) then
      OnAddedUndo(Self);
  end;
end;

procedure TBCEditorUndoList.Unlock;
begin
  if FLockCount > 0 then
    Dec(FLockCount);
end;

function TBCEditorUndoList.LastChangeReason: TBCEditorChangeReason;
begin
  if FItems.Count = 0 then
    Result := crNothing
  else
    Result := TBCEditorUndoItem(FItems[FItems.Count - 1]).ChangeReason;
end;

function TBCEditorUndoList.LastChangeBlockNumber: Integer;
begin
  if FItems.Count = 0 then
    Result := 0
  else
    Result := TBCEditorUndoItem(FItems[FItems.Count - 1]).ChangeBlockNumber;
end;

function TBCEditorUndoList.LastChangeString: string;
begin
  if FItems.Count = 0 then
    Result := ''
  else
    Result := TBCEditorUndoItem(FItems[FItems.Count - 1]).ChangeString;
end;

procedure TBCEditorUndoList.AddGroupBreak;
var
  LTextPosition: TBCEditorTextPosition;
begin
  if (LastChangeBlockNumber = 0) and (LastChangeReason <> crGroupBreak) then
    AddChange(crGroupBreak, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
end;

function TBCEditorUndoList.GetItems(const AIndex: Integer): TBCEditorUndoItem;
begin
  Result := TBCEditorUndoItem(FItems[AIndex]);
end;

procedure TBCEditorUndoList.SetItems(const AIndex: Integer; const AValue: TBCEditorUndoItem);
begin
  FItems[AIndex] := AValue;
end;

end.
