unit Winapi.Hooks;

interface
{$REGION 'History'}
//  06-Mar-2020 - Updated, replaced MakeObjectInstance with madTools.MethodToProcedure
//              - Now uses simple access to Pointer Records and Record Helpers to translate keys on demand
{$ENDREGION}
{$T-} // In the {$T-} state, the result of the @ operator is always an untyped pointer (Pointer) that is compatible with all other pointer types.

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  madTools;

type
  PMsllHookStruct = ^MSLLHOOKSTRUCT;
  MSLLHOOKSTRUCT = packed record
    pt: TPoint;
    mouseData: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;
  TMsllHookStruct = MSLLHOOKSTRUCT;

  PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;
  KBDLLHOOKSTRUCT = packed record
    vkCode: DWORD;
    ScanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;
  TKBDLLHookStruct = KBDLLHOOKSTRUCT;

  TKeyStatesFlags = (
    /// <summary>
    ///   24: Indicates whether the key is an extended key, such as a function key or a key on the numeric keypad. The value is 1 if the key is an extended key; otherwise, it is 0
    /// </summary>
    kbExtended,
    kbReserved_25, kbReserved_26, kbReserved_27, kbReserved_28,
    /// <summary>
    ///   29: The context code. The value is 1 if the ALT key is down; otherwise, it is 0.
    /// </summary>
    kbAltDwn,
    /// <summary>
    ///   30: The previous key state. The value is 1 if the key is down before the message is sent; it is 0 if the key is up.
    /// </summary>
    kbPrevState,
    /// <summary>
    ///   31: The transition state. The value is 0 if the key is being pressed and 1 if it is being released.
    /// </summary>
    kbTransitionState);

  PKeyStates = ^TKeyStates;
  /// <summary>
  ///   Keystroke Message Flags &lt;br /&gt;First 32 bits of LParam
  /// </summary>
  TKeyStates = record
    case LPARAM of
      0: (
          /// <summary>
          ///   0-15: The repeat count. The value is the number of times the keystroke is repeated as a result of the user's holding down the key
          /// </summary>
          TimesRepeated: uint16;
           /// <summary>
           ///   16-23: The scan code. The value depends on the OEM.
           /// </summary>
           ScanCode: uint8;
           /// <summary>
           ///   24-34: Flags
           /// </summary>
           Flags: set of TKeyStatesFlags);
      1: (
          /// <summary>
          ///   LParam is signed but differs in Bitness
          /// </summary>
          lParam: LPARAM);
  end;

  /// <summary>
  ///   Simplifies access to flag data
  /// </summary>
  TKeyStatesHelper = record helper for TKeyStates
    function AltDown: Boolean; inline;
    function CtrlDown: Boolean; inline;
    function ExtendKey: Boolean; inline;
    function ShiftDown: Boolean; inline;
    function IsKeyDown: Boolean; inline;
  end;

  /// <summary>
  ///   Simplifies access to flag data
  /// </summary>
  TKBDLLHookStructHelper = record helper for TKBDLLHookStruct
    function AltDown: Boolean; inline;
    function CtrlDown: Boolean; inline;
    function ExtendKey: Boolean; inline;
    function InjectedKey: Boolean; inline;
    function ShiftDown: Boolean; inline;
    function IsKeyDown: Boolean; inline;
  end;

  /// <summary>
  ///   Newly declared, the original method had No 'Code' and only Cardinal wParam due to MakeObjectInstance
  /// </summary>
  THookMessage =  record
    Code : Integer;
    wParam: WPARAM;
    lParam: LPARAM;
    Handled: LongBool;
  end;

  THook = class;
  THookNotify = reference to procedure(AHook: THook; var AHookMsg: THookMessage);

  /// <summary>
  ///   Replaced MakeObjectInstance with MethodToProcedure
  /// </summary>
  /// <remarks>
  ///   <list type="bullet">
  ///     <item>
  ///       <b>MakeObjectInstance</b><br />Testing in x64 shows that even though TFNHookProc takes a WPARAM which is a UINT64 the TMessage only brings along the Cardinal part
  ///       of it, furthermore it always looses the first parameter expecting it to be the value of Self. So we had no access to iCode using this method.
  ///     </item>
  ///     <item>
  ///       <b>MethodToProcedure</b><br />From madTools, works like a charm will need to use this more often. <br />
  ///     </item>
  ///   </list>
  /// </remarks>
  /// <seealso href="http://help.madshi.net/MethodToProc.htm">
  ///   MethodToProcedure
  /// </seealso>
  TCustomHook = class abstract
  strict private
    FActive: Boolean;
    FHook: hHook;
    FHookProc: Pointer;
    FThreadID: Integer;

    FOnPreExecute: THookNotify;
    FOnPostExecute: THookNotify;
    function FNHookProc(iCode : integer; wParam : WPARAM; lParam: LPARAm): LResult; stdcall;
    procedure SetActive(const AValue: Boolean);
  protected
    function GetHookID: Integer; virtual; abstract;
    procedure PreExecute(var AHookMsg: THookMessage); virtual;
    procedure PostExecute(var AHookMsg: THookMessage); virtual;

    property Active: Boolean read FActive write SetActive;
    property OnPreExecute: THookNotify read FOnPreExecute write FOnPreExecute;
    property OnPostExecute: THookNotify read FOnPostExecute write FOnPostExecute;

    property ThreadID: Integer read FThreadID write FThreadID;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  THook = class abstract(TCustomHook)
  public
    property Active;
    property OnPreExecute;
    property OnPostExecute;
    property ThreadID;
  end;

  /// <summary>
  ///   The WH_CALLWNDPROC and WH_CALLWNDPROCRET hooks enable you to monitor messages sent to window procedures. The system calls a WH_CALLWNDPROC hook procedure before passing
  ///   the message to the receiving window procedure, and calls the WH_CALLWNDPROCRET hook procedure after the window procedure has processed the message.
  /// </summary>
  TCallWndProcHook = class sealed(THook)
  private
    FCWPStruct: PCWPStruct;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    property CWPStruct: PCWPStruct read FCWPStruct;
  end;

  /// <summary>
  ///   The WH_CALLWNDPROC and WH_CALLWNDPROCRET hooks enable you to monitor messages sent to window procedures. The system calls a WH_CALLWNDPROC hook procedure before passing
  ///   the message to the receiving window procedure, and calls the WH_CALLWNDPROCRET hook procedure after the window procedure has processed the message.
  /// </summary>
  TCallWndProcRetHook = class sealed(THook)
  private
    FCWPRetStruct: PCWPRetStruct;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    property CWPRetStruct: PCWPRetStruct read FCWPRetStruct;
  end;

  /// <summary>
  ///   The system calls a WH_CBT hook procedure before activating, creating, destroying, minimizing, maximizing, moving, or sizing a window; before completing a system command;
  ///   before removing a mouse or keyboard event from the system message queue; before setting the input focus; or before synchronizing with the system message queue. The value
  ///   the hook procedure returns determines whether the system allows or prevents one of these operations. The WH_CBT hook is intended primarily for computer-based training
  TCBTHook = class sealed(THook)
  protected
    function GetHookID: Integer; override;
  end;

  /// <summary>
  ///   The system calls a WH_DEBUG hook procedure before calling hook procedures associated with any other hook in the system. You can use this hook to determine whether to allow
  ///   the system to call hook procedures associated with other types of hooks.
  /// </summary>
  TDebugHook = class sealed(THook)
  private
    FDebugHookInfo: PDebugHookInfo;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    property DebugHookInfo: PDebugHookInfo read FDebugHookInfo;
  end;

  /// <summary>
  ///   The WH_GETMESSAGE hook enables an application to monitor messages about to be returned by the GetMessage or PeekMessage function. You can use the WH_GETMESSAGE hook to
  ///   monitor mouse and keyboard input and other messages posted to the message queue.
  /// </summary>
  TGetMessageHook = class sealed(THook)
  private
    FMsg : PMsg;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    property Msg : PMsg read FMsg;
  end;

  /// <summary>
  ///   Can Not be a Thread Hook
  /// </summary>
  TJournalPlaybackHook = class sealed(THook)
  protected
    function GetHookID: Integer; override;
  end experimental; // 'Blocked by Win 1984'

  /// <summary>
  ///   Can Not be a Thread Hook
  /// </summary>
  TJournalRecordHook = class sealed(THook)
  protected
    function GetHookID: Integer; override;
  end experimental; // 'Blocked by Win 1984'

  /// <summary>
  ///   The WH_KEYBOARD hook enables an application to monitor message traffic for WM_KEYDOWN and WM_KEYUP messages about to be returned by the GetMessage or PeekMessage function.
  ///   You can use the WH_KEYBOARD hook to monitor keyboard input posted to a message queue.
  /// </summary>
  TKeyboardHook = class sealed(THook)
  private
    FKeyState: PKeyStates;
  protected
    procedure PreExecute(var AHookMsg: THookMessage); override;
    function GetHookID: Integer; override;
  public
    /// <summary>
    ///   The Key's Extended name like "A,Esc,Num 4"
    /// </summary>
    function GetKeyExtName(const AHookMsg: THookMessage): string;
    /// <summary>
    ///   Unicode Character representing the key else #0
    /// </summary>
    function GetKeyChar(const AHookMsg: THookMessage): Char;
    /// <summary>
    ///   Read/Write Access to Key States
    /// </summary>
    property KeyStates: PKeyStates read FKeyState;
  end;

  /// <summary>
  ///   The WH_MOUSE hook enables you to monitor mouse messages about to be returned by the GetMessage or PeekMessage function. You can use the WH_MOUSE hook to monitor mouse
  ///   input posted to a message queue.
  /// </summary>
  TMouseHook = class sealed(THook)
  private
    FHookStruct : PMOUSEHOOKSTRUCT;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    /// <summary>
    ///   Read/Write Access to Mouse Data
    /// </summary>
    property HookStruct: PMOUSEHOOKSTRUCT read FHookStruct write FHookStruct;
  end;

  /// <summary>
  ///   The WH_MSGFILTER and WH_SYSMSGFILTER hooks enable you to monitor messages about to be processed by a menu, scroll bar, message box, or dialog box, and to detect when a
  ///   different window is about to be activated as a result of the user's pressing the ALT+TAB or ALT+ESC key combination. The WH_MSGFILTER hook can only monitor messages passed
  ///   to a menu, scroll bar, message box, or dialog box created by the application that installed the hook procedure. The WH_SYSMSGFILTER hook monitors such messages for all
  TMsgHook = class sealed(THook)
  protected
    function GetHookID: Integer; override;
  end;

  TShellHook = class sealed(THook)
  protected
    function GetHookID: Integer; override;
  end;

  TSysMsgHook = class sealed(THook)
  protected
    function GetHookID: Integer; override;
  end;

  /// <summary>
  ///   The WH_KEYBOARD_LL hook enables you to monitor keyboard input events about to be posted in a thread input queue.
  /// </summary>
  TLowLevelKeyboardHook = class sealed(THook)
   type
  private
    FHookStruct: PKBDLLHookStruct;
    function GetKeyChar: Char;
    function GetKeyExtName: string;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    /// <summary>
    ///   Read/Write Access to Key States <br />
    /// </summary>
    property HookStruct: PKBDLLHookStruct read FHookStruct;
    property KeyChar: Char read GetKeyChar;
    property KeyExtName: string read GetKeyExtName;
  end;

  /// <summary>
  ///   The WH_MOUSE_LL hook enables you to monitor mouse input events about to be posted in a thread input queue.
  /// </summary>
  TLowLevelMouseHook = class sealed(THook)
  strict private
    FHookStruct: PMSLLHookStruct;
  protected
    function GetHookID: Integer; override;
    procedure PreExecute(var AHookMsg: THookMessage); override;
  public
    /// <summary>
    ///   Read/Write Access to Mouse Data
    /// </summary>
    property HookStruct: PMSLLHookStruct read FHookStruct;
  end;

type
  THookContainer<T: THook, constructor> = class(TComponent)
  private
    FHook: T;
  public
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    class function Construct(AOwner: TComponent): T;
    property Hook: T read FHook;
  end;

  THookInstance<T: THook, constructor> = record
  public
    class function CreateHook(AOwner: TComponent): T; static;
  end;


implementation

const
  MAX_KEY_NAME_LENGTH = 100;
  SHIFTED = $8000;
 (*
    * Low level hook flags
  *)
  LLKHF_EXTENDED = $01;
  LLKHF_INJECTED = $10;
  LLKHF_ALTDOWN = $20;
  LLKHF_UP = $80;

{ TCustomHook }

constructor TCustomHook.Create;
{$REGION 'History'}
//  07-Mar-2020 - replaced MakeObjectInstance with madTools.MethodToProcedure
{$ENDREGION}
begin
  inherited;
  FHookProc := madTools.MethodToProcedure(Self, @TCustomHook.FNHookProc, 3);
//** TFNHookProc(FHookProc)(MAXINT,MAXLONGLONG,MAXLONGLONG);
  FHook := 0;
  FActive := False;
  FThreadID := GetCurrentThreadID;
end;

destructor TCustomHook.Destroy;
begin
  Active := False;
  VirtualFree(FHookProc, 0, MEM_RELEASE);
//  FreeObjectInstance(FHookProc); see class documentation
  inherited;
end;

function TCustomHook.FNHookProc(iCode: integer; wParam: WPARAM; lParam: LPARAm): LResult;
var LHookMsg: THookMessage;
begin
  LHookMsg.Code    := iCode;
  LHookMsg.wParam  := wParam;
  LHookMsg.lParam  := lParam;
  LHookMsg.Handled := False;
  PreExecute(LHookMsg);
  if not LHookMsg.Handled then begin
    Result := CallNextHookEx(FHook, LHookMsg.Code, LHookMsg.wParam, LHookMsg.lParam);
    PostExecute(LHookMsg);
  end else Result := Ord(LHookMsg.Handled); // Non Zero
end;

procedure TCustomHook.PostExecute(var AHookMsg: THookMessage);
begin
  if Assigned(FOnPostExecute) then
    FOnPostExecute(THook(Self), AHookMsg)
end;

procedure TCustomHook.PreExecute(var AHookMsg: THookMessage);
begin
  if Assigned(FOnPreExecute) then
    FOnPreExecute(THook(Self), AHookMsg);
end;

procedure TCustomHook.SetActive(const AValue: Boolean);
var ID: Integer;
begin
  if FActive = AValue then Exit;
  FActive := AValue;

  If Active then begin
    ID := GetHookID;
    if ID in [WH_KEYBOARD_LL, WH_MOUSE_LL] then
      FThreadID := 0;
    FHook := SetWindowsHookEx(GetHookID, FHookProc, HInstance, FThreadID);
    if (FHook = 0) then begin
      FActive := False;
      raise Exception.Create(Classname + ' CREATION FAILED!');
    end;
  end else begin
    if (FHook <> 0) then
      UnhookWindowsHookEx(FHook);
    FHook := 0;
  end;
end;

{ TLowLevelKeyboardHook }

function TLowLevelKeyboardHook.GetHookID: Integer;
begin
  Result := WH_KEYBOARD_LL;
end;

function TLowLevelKeyboardHook.GetKeyChar: Char;
{$REGION 'History'}
//  08-Mar-2020 - Created, on demand access to Char
{$ENDREGION}
var
  KBS: TKeyboardState;
  CharCount: Integer;
  Value : string;
begin
  GetKeyboardState(KBS);
  try
    SetLength(Value, 4);
    CharCount := ToUnicode(FHookStruct.vkCode, FHookStruct.ScanCode, KBS, Pchar(Value), 4, 0);
  except
    CharCount := 1;
  end;

  Result := #0;
  if CharCount > 0 then Result := Value.Chars[0];
end;

function TLowLevelKeyboardHook.GetKeyExtName: string;
{$REGION 'History'}
//  08-Mar-2020 - Created, on demand access to Key Name
{$ENDREGION}
var i : integer;  dwMsg: DWORD;
begin
  dwMsg := 1;
  dwMsg := dwMsg + (FHookStruct.ScanCode shl 16);
  dwMsg := dwMsg + (FHookStruct.flags shl 24);
  SetLength(Result, MAX_KEY_NAME_LENGTH);
  i := GetKeyNameText(dwMsg, Pchar(Result), MAX_KEY_NAME_LENGTH);
  SetLength(Result, i);
end;

procedure TLowLevelKeyboardHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FHookStruct      := PKBDLLHOOKSTRUCT(AHookMsg.LParam);
  inherited;
end;

{ TCallWndProcHook }

function TCallWndProcHook.GetHookID: Integer;
begin
  Result := WH_CALLWNDPROC;
end;

procedure TCallWndProcHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FCWPStruct := PCWPStruct(AHookMsg.LParam);
  inherited;
end;

{ TCallWndProcRetHook }

function TCallWndProcRetHook.GetHookID: Integer;
begin
  Result := WH_CALLWNDPROCRET;
end;

procedure TCallWndProcRetHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FCWPRetStruct := pCWPRetStruct(AHookMsg.LParam);
  inherited;
end;

{ TCBTHook }

function TCBTHook.GetHookID: Integer;
begin
  Result := WH_CBT;
end;

{ TDebugHook }

function TDebugHook.GetHookID: Integer;
begin
  Result := WH_DEBUG;
end;

procedure TDebugHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FDebugHookInfo := PDebugHookInfo(AHookMsg.LParam);
  inherited;
end;

{ TGetMessageHook }

function TGetMessageHook.GetHookID: Integer;
begin
  Result := WH_GETMESSAGE;
end;

procedure TGetMessageHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FMsg             := PMsg(AHookMsg.lParam);
  inherited;
end;

{ TJournalPlaybackHook }

function TJournalPlaybackHook.GetHookID: Integer;
begin
  Result := WH_JOURNALPLAYBACK;
end;

{ TJournalRecordHook }

function TJournalRecordHook.GetHookID: Integer;
begin
  Result := WH_JOURNALRECORD;
end;

{ TKeyboardHook }

function TKeyboardHook.GetHookID: Integer;
begin
  Result := WH_KEYBOARD;
end;

procedure TKeyboardHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FKeyState := @AHookMsg.LParam;
  inherited;
end;

function TKeyboardHook.GetKeyExtName(const AHookMsg: THookMessage): string;
{$REGION 'History'}
//  08-Mar-2020 - Created, on demand access to Key Name
{$ENDREGION}
var i : integer;
begin
  SetLength(Result, MAX_KEY_NAME_LENGTH);
  i := GetKeyNameText(AHookMsg.LParam, Pchar(Result), MAX_KEY_NAME_LENGTH);
  SetLength(Result, i);
end;

function TKeyboardHook.GetKeyChar(const AHookMsg: THookMessage): Char;
{$REGION 'History'}
//  08-Mar-2020 - Created, on demand access to Char
{$ENDREGION}
var
  KBS: TKeyboardState;
  CharCount: Integer;
  Value : string;
begin
  GetKeyboardState(KBS);
  try
    SetLength(Value, 4);
    CharCount := ToUnicode(AHookMsg.WParam, AHookMsg.LParam, KBS, Pchar(Value), 4, 0);
  except
    CharCount := 1;
  end;

  Result := #0;
  if CharCount > 0 then Result := Value.Chars[0];
end;

{ TMouseHook }

function TMouseHook.GetHookID: Integer;
begin
  Result := WH_MOUSE;
end;

procedure TMouseHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FHookStruct    := PMOUSEHOOKSTRUCT(AHookMsg.LParam);
  inherited;
end;

{ TMsgHook }

function TMsgHook.GetHookID: Integer;
begin
  Result := WH_MSGFILTER;
end;

{ TShellHook }

function TShellHook.GetHookID: Integer;
begin
  Result := WH_SHELL;
end;

{ TSysMsgHook }

function TSysMsgHook.GetHookID: Integer;
begin
  Result := WH_SYSMSGFILTER;
end;

{ TLowLevelMouseHook }

function TLowLevelMouseHook.GetHookID: Integer;
begin
  Result := WH_MOUSE_LL;
end;

procedure TLowLevelMouseHook.PreExecute(var AHookMsg: THookMessage);
{$REGION 'History'}
//  08-Mar-2020 - Get Out if Code is less than Zero, Hook specific
{$ENDREGION}
begin
  if (AHookMsg.Code < 0) then Exit;
  FHookStruct := PMSLLHOOKSTRUCT(AHookMsg.WParam);
  inherited;
end;

{ THookInstance<T> }

class function THookInstance<T>.CreateHook(AOwner: TComponent): T;
begin
  Result := THookContainer<T>.Construct(AOwner)
end;


{ THookContainer<T> }

class function THookContainer<T>.Construct(AOwner: TComponent): T;
begin
  Result := THookContainer<T>.Create(AOwner).FHook;
end;

constructor THookContainer<T>.Create(AOwner: TComponent);
begin
  inherited;
  FHook := T.Create;
end;

destructor THookContainer<T>.Destroy;
begin
  FHook.Free;
  inherited;
end;

function TKBDLLHookStructHelper.AltDown: Boolean;
begin
  Result := (flags and LLKHF_ALTDOWN) <> 0;
end;

function TKBDLLHookStructHelper.CtrlDown: Boolean;
begin
  Result := vkCode in [VK_LCONTROL, VK_RCONTROL];
end;

function TKBDLLHookStructHelper.ExtendKey: Boolean;
begin
  Result := (flags and LLKHF_EXTENDED) <> 0;
end;

function TKBDLLHookStructHelper.InjectedKey: Boolean;
begin
  Result := (flags and LLKHF_INJECTED) <> 0;
end;

function TKBDLLHookStructHelper.ShiftDown: Boolean;
begin
  Result := vkCode in [VK_LSHIFT, VK_RSHIFT];
end;

function TKBDLLHookStructHelper.IsKeyDown: Boolean;
begin
  Result := (flags and LLKHF_UP) = 0;
end;

function TKeyStatesHelper.AltDown: Boolean;
begin
  Result := (kbAltDwn in Flags);
end;

function TKeyStatesHelper.CtrlDown: Boolean;
begin
  Result := MapVirtualKey(ScanCode, MAPVK_VSC_TO_VK) = VK_CONTROL;
end;

function TKeyStatesHelper.ExtendKey: Boolean;
begin
  Result := (kbExtended in Flags);
end;

function TKeyStatesHelper.IsKeyDown: Boolean;
begin
  // Bit 31: The transition state. The value is 0 if the key is being pressed and 1 if it is being released.
  Result := not (kbTransitionState in Flags);
end;

function TKeyStatesHelper.ShiftDown: Boolean;
begin
  Result := MapVirtualKey(ScanCode, MAPVK_VSC_TO_VK) = VK_SHIFT;
end;

end.
