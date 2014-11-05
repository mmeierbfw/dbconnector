unit udbconnector;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, uutils,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.Phys.MySQL, Data.DB,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, Vcl.StdCtrls, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, ZAbstractTable, ZDataset, ZAbstractRODataset,
  ZAbstractDataset, ZAbstractConnection, ZConnection,
  System.Generics.collections, uconstants, shellapi, Vcl.Grids, Vcl.DBGrids,
  Data.FMTBcd, Data.SqlExpr, Datasnap.DBClient, strutils;

type
  Tformdb = class(TForm)
    ZConnection1: TZConnection;
    ZQuery1: TZQuery;
    DBGrid1: TDBGrid;
    Button1: TButton;
    DataSource1: TDataSource;
    queryauftr�ge: TZQuery;
    dsauftr�ge: TDataSource;
    queryableser: TZQuery;
    dsableser: TDataSource;
    queryauftraggeber: TZQuery;
    dsauftraggeber: TDataSource;
    ZConnection2: TZConnection;
    querynutzer: TZQuery;
    dsnutzer: TDataSource;
    querycount: TZQuery;
    dscount: TDataSource;
    queryupdate: TZQuery;
    dsupdate: TDataSource;
    queryanforderungen: TZQuery;
    dsanforderungen: TDataSource;
    queryunbearbeitet: TZQuery;
    dsunbearbeitet: TDataSource;
    querydelete: TZQuery;
    dsdelete: TDataSource;
    queryzwi: TZQuery;
    dszwi: TDataSource;
    dsen: TDataSource;
    queryen: TZQuery;
    querymon: TZQuery;
    dsmon: TDataSource;
    ZQuery2: TZQuery;
    dsnuter: TDataSource;
    queryrekl: TZQuery;
    dsrekl: TDataSource;
    querynuliste: TZQuery;
    dsnuliste: TDataSource;
    querykn: TZQuery;
    dskn: TDataSource;
    procedure Button1Click(Sender: TObject);
    // procedure Button1Click(Sender: TObject);
  private
    function createCloze(startstr, database: string;
      values: Tdictionary<string, string>): string;
    function createquery(database, wherestring: string;
      query: TStringlist): string;
    function createRunningNumerQuery(kundennummer: integer;
      table, sachbearbeiter: string): string; overload;
    function createRunningNumerQuery(kundennummer: integer;
      sachbearbeiter: string): string; overload;
    function exec(query: string): boolean;
  public
    procedure doquery(zquery: TZQuery; database: string; wherestring: string;
      query: TStringlist);

    function get(database, wherestring: string; query: TStringlist)
      : Tdictionary<string, string>; overload;
    function get(zquery: TZQuery; database, wherestring: string;
      query: TStringlist): Tdictionary<string, string>; overload;

    function getfromHN(database, table, wherestring: string; list: TStringlist)
      : Tdictionary<string, string>; overload;
    function showquery(query: string): boolean;
    function connect(): boolean; overload;
    function connect(query: TZQuery): boolean; overload;
    function getno(kundennummer: integer; table, sb: string): integer;
    function insertquery(database: string;
      values: Tdictionary<string, string>): boolean;
    function doupdate(query: string): boolean;
    procedure RunFile(const aFile, cmdLine: string; WindowState: Word);
    function disconnect: boolean;
    function count(value, table, query: string): integer;
    function update(id, table, key, value: string): boolean;

    function countdistinct(value, table, query: string): integer;
    function getmaxno(kn, sb: string): string;
    function replacequery(table: string;
      values: Tdictionary<string, string>): boolean;
    function delete(table, query: string): boolean;
    function getkundennr(kdn: string): TList<integer>;
  end;

var
  formdb: Tformdb;
  sei   : TShellExecuteInfo;

implementation

{$R *.dfm}
{ TForm1 }

procedure Tformdb.RunFile(const aFile, cmdLine: string; WindowState: Word);
begin
  FillChar(sei, SizeOf(sei), 0);
  sei.cbSize       := SizeOf(sei);
  sei.fMask        := SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS;
  sei.lpVerb       := 'open';
  sei.lpFile       := PChar(aFile);
  sei.lpDirectory  := PChar(ExtractFileDir(aFile));
  sei.lpParameters := PChar(cmdLine);
  sei.nShow        := WindowState;

  if not ShellExecuteEx(@sei) then RaiseLastOSError;
  if sei.hProcess <> 0 then begin
    while WaitForSingleObject(sei.hProcess, 50) = WAIT_TIMEOUT do
        Application.ProcessMessages;
    CloseHandle(sei.hProcess);
  end;
end;

function Tformdb.connect(): boolean;
begin
  Result := connect(ZQuery1);
end;

{ erzeuge einen L�ckentext, um m�glichst dynamische Abfragen gestalten zu k�nnen }
procedure Tformdb.Button1Click(Sender: TObject);
begin
  ZQuery1.SQL.Text :=
    'Select Eintragsdatum, Liegenschaft from Auftragsanforderung;';
  ZQuery1.Open;
end;

function Tformdb.connect(query: TZQuery): boolean;

var
  res    : boolean;
  exename: string;
begin
  // if not Assigned(query) then query := TZQuery.Create(nil);
  if query = nil then query := TZQuery.create(nil);

  // exename := IncludeTrailingPathDelimiter(ExtractFilePath(Application.exename))
  // + 'plink.exe';
  // RunFile(exename,
  // '-ssh 148.251.138.2 -l tiffy  -L 7777:127.0.0.1:3306 -pw maunze01',
  // sw_hide);
  ZConnection1.LibraryLocation := ExtractFilePath(Application.exename) +
    'libmysql.dll';
  if not Assigned(ZConnection1) then ZConnection1 := TZConnection.create(self);
  if not Assigned(ZQuery1) then ZQuery1           := TZQuery.create(self);
  try
    ZConnection1.user     := 'tiffy';
    ZConnection1.Password := 'maunze01';
    ZConnection1.port     := 7777;
    ZConnection1.hostname := '127.0.0.1';
    ZConnection1.database := database;

    if not ZConnection1.Connected then ZConnection1.connect;
    query.Connection := ZConnection1;
    res              := query.Connection.Connected;
    Result           := res;
  except
    on e: exception do begin
      OutputDebugString
        (PChar('es kann keine Verbindung zur Datenbank hergestellt werden'));

    end;
  end;
end;

// --------------------------------------------------------------

function Tformdb.countdistinct(value, table, query: string): integer;
begin
  value  := 'DISTINCT ' + value;
  Result := count(value, table, query);
end;

// -----------------------------------------------------

function Tformdb.count(value, table, query: string): integer;
var
  SQL: string;
begin
  SQL := 'SELECT COUNT( ' + value + ')   AS val FROM ' + table + ' ' + query;
  querycount.SQL.Text := SQL;
  querycount.Open;
  Result := querycount.FieldByName('val').AsInteger;
end;

function Tformdb.createCloze(startstr, database: string;
  values: Tdictionary<string, string>): string;
var
  str      : string;
  cnt, size: integer;
  key      : string;
begin
  str := Format(insertBegin, [startstr, database]);
  for key in values.Keys do begin
    str := str + key + ', ';
  end;
  str := copy(str, 1, length(str) - 2); // das letzte Komma wieder l�schen
  str := str + insertMiddle;
  for key in values.Keys do begin
    str := str + QuotedStr(values.Items[key]) + ', ';
  end;
  str := copy(str, 1, length(str) - 2); // das letzte Komma wieder l�schen

  str    := str + insertEnd;
  Result := str;
end;

function Tformdb.createquery(database, wherestring: string;
  query: TStringlist): string;
var
  querystring: string;
  attr       : string;
begin
  querystring                      := 'SELECT ';
  for attr in query do querystring := querystring + attr + ', ';
  querystring := copy(querystring, 1, length(querystring) - 2)
  // das letzte Komma l�schen
    + ' FROM ' + database + ' ' + wherestring + ';';
  Result := querystring;
end;

function Tformdb.createRunningNumerQuery(kundennummer: integer;
  sachbearbeiter: string): string;
var
  query    : string;
  cnt, size: integer;
  f        : textfile;
  list     : TStringlist;
begin
  Result := Format
    ('SELECT Dokumentid.dokumentid FROM Dokumentid WHERE sachbearbeiter = %d',
    [strtoint(sachbearbeiter)]);
end;

function Tformdb.createRunningNumerQuery(kundennummer: integer;
  table, sachbearbeiter: string): string;
var
  query    : string;
  cnt, size: integer;
  f        : textfile;
begin
  query := Format
    ('SELECT MAX(dokumentid) AS max FROM %s WHERE kundennummer = %d AND sachbearbeiter = %s ',
    [table, kundennummer, sachbearbeiter]);
  Result := query;

end;

function Tformdb.delete(table, query: string): boolean;
var
  SQL: string;
begin
  if not connect then Begin
    OutputDebugString('keine Datenbankverbindung m�glich');
    exit;
  End;
  try
    SQL := Format('DELETE FROM %S WHERE %S;', [table, query]);
    querydelete.SQL.Clear;
    querydelete.SQL.Add(SQL);
    querydelete.ExecSQL;
    Result := true;
  except
    on e: exception do begin
      ShowMessage(e.Message);
      Result := false;
    end;
  end;
end;

function Tformdb.disconnect: boolean;
begin
  try
    // TerminateProcess(sei.hProcess, 0);
      ZConnection1.disconnect;
  except OutputDebugString('Verbindung kann nicht geschlossen werden');
  end;
end;

procedure Tformdb.doquery(zquery: TZQuery; database: string;
  wherestring: string; query: TStringlist);

var
  Ds         : tdataset;
  res        : Tdictionary<string, string>;
  attr, value: string;
  count      : integer;
  SQL        : string;
  datasource : TDataSource;
begin
  try

    if not connect() then begin
      OutputDebugString('keine Datenbankverbindung m�glich');
      exit;
    end;
    try
      SQL             := createquery(database, wherestring, query);
      zquery.Filtered := false;
      zquery.filter   := '';
      zquery.SQL.Clear;
      zquery.SQL.Add(SQL);
      zquery.Open;
    except
      on e: exception do begin
        ShowMessage(e.Message);
      end;

    end;
  finally
  end;
end;

function Tformdb.doupdate(query: string): boolean;

var
  help: integer;
begin
  try
    if not connect then exit;
    try
      ZQuery1.SQL.Add
        ('update Auftragsanforderung set Auftragsanforderung.AnforderungAbgeschlossen=1 where id=1');
      ZQuery1.ExecSQL;
      // DBGrid1.DataSource.DataSet.open;
      // help := ZQuery1.RecordCount;
      // showmessage(inttostr(help) + ' ergebnisse');
      // DBGrid1.DataSource := ZQuery1.DataSource;
      // formdb.Show;
      Result := true;
    except
      on e: exception do begin
        OutputDebugString(PChar(e.Message));

        Result := false;
      end;
    end;

  finally

  end;
end;

function Tformdb.exec(query: string): boolean;
begin
  Result := false;
  try

    Screen.Cursor := crHourGlass;

    OutputDebugString(PChar(query));
    // query := 'insert into Auftr�ge(Telefonnummer,email, ablesedienst, notizen, abrechnungsende, nutzernummer) values("","","","","","");';
    if not connect then exit;
    try
      ZQuery1.SQL.Clear;
      ZQuery1.SQL.Text := query;
      ZQuery1.ExecSQL;
      Result := true;
    except
      on e: exception do ShowMessage(PChar(e.Message));
    end;
  finally Screen.Cursor := crDefault;
    // disconnect;
  end;
end;

function Tformdb.get(zquery: TZQuery; database, wherestring: string;
  query: TStringlist): Tdictionary<string, string>;
var
  res        : Tdictionary<string, string>;
  attr, value: string;
  count      : integer;
  datasource : TDataSource;
  field      : string;
begin
  res := Tdictionary<string, string>.create();
  try
    if not connect then exit;
    zquery.SQL.Text := createquery(database, wherestring, query);
    zquery.Open;
    count := zquery.RecordCount;
    if count = 0 then exit;
    for attr in query do begin
      if strcontains('.', attr) then begin
        field := getlast('.', attr);
      end
      else field := attr;

      value := zquery.FieldByName(field).AsString;
      res.Add(field, value);
    end;
  finally Result := res;
  end;
end;

function Tformdb.getfromHN(database, table, wherestring: string;
  list: TStringlist): Tdictionary<string, string>;
var
  res        : Tdictionary<string, string>;
  attr, value: string;
begin
  try
    OutputDebugString(PChar(database));
    res                          := Tdictionary<string, string>.create();
    ZConnection2.LibraryLocation := ExtractFilePath(Application.exename) +
      'sqlite3.dll';
    ZConnection2.database := database;
    if not ZConnection2.Connected then ZConnection2.connect;
    if not ZConnection2.Connected then exit;

    querynutzer.SQL.Text   := createquery(table, wherestring, list);
    querynutzer.Connection := ZConnection2;
    querynutzer.Open;
    for attr in list do begin
      value := querynutzer.FieldByName(attr).AsString;
      res.Add(attr, value);
    end;
  finally
    // ZConnection2.disconnect;
    // Result := res;
  end;
end;

function Tformdb.getkundennr(kdn: string): TList<integer>;
var
  query: string;
begin
  Result := TList<integer>.create;
  query  := Format('SELECT ordner_id FROM kunden WHERE kdn = %s', [kdn]);
  try
    // if not Assigned(querykn) then querykn := TZQuery.create(self);
    //
    // connect(querykn);
    // if not connect(querykn) then exit;

    exec(query);
    with ZQuery1 do begin
      // SQL.Clear;
      // SQL.Add('SELECT ordner_id FROM kunden WHERE kdn = :kdn');
      // ParamByName('kdn').AsString := kdn;
      // Open;
      while not Eof do begin
        Result.Add(FieldByName('ordner_id').AsInteger);
        next;
      end;
    end;

  except
    on e: exception do begin
      ShowMessage(e.Message);
    end;

  end;
end;

function Tformdb.getmaxno(kn, sb: string): string;
var
  res          : string;
  doctypestring: string;
  query        : string;
begin
  try
    if connect() then begin
      query := createRunningNumerQuery(strtoint(kn), sb);
      OutputDebugString(PChar(query));
      ZQuery1.SQL.Text := query;
      try
        ZQuery1.Open;
        res      := ZQuery1.FieldByName('Dokumentid').AsString;
      except res := '0';
      end;
    end else begin
      res := '0';
      OutputDebugString
        ('es kann keine Verbindung zur Datenbank hergestellt werden');
    end;
  finally
    Screen.Cursor := crDefault;
    // disconnect;
    ZQuery1.Close;
    if res = '' then res := '0';
    
    Result := inttostr(strtoint(res) + 1);
  end;
end;

function Tformdb.get(database, wherestring: string; query: TStringlist)
  : Tdictionary<string, string>;
var
  res        : Tdictionary<string, string>;
  attr, value: string;
  count      : integer;
  datasource : TDataSource;
begin
  res := Tdictionary<string, string>.create();
  try
    if not connect then exit;
    ZQuery1.SQL.Text := createquery(database, wherestring, query);
    try ZQuery1.Open;
    except
      on e: exception do begin
        ShowMessage(e.Message);
      end;

    end;
    count := ZQuery1.RecordCount;
    if count = 0 then exit;
    for attr in query do begin
      value := ZQuery1.FieldByName(attr).AsString;
      res.Add(attr, value);
    end;
  finally Result := res;
  end;
end;

function Tformdb.getno(kundennummer: integer; table, sb: string): integer;
var
  res          : string;
  doctypestring: string;
  query        : string;
begin
  try
    Application.ProcessMessages;
    if connect() then begin
      query := createRunningNumerQuery(kundennummer, table, sb);
      OutputDebugString(PChar(query));
      ZQuery1.SQL.Text := query;
      try
        ZQuery1.Open;
        res      := ZQuery1.FieldByName('max').AsString;
      except res := '0';
      end;
    end else begin
      res := '0';
      OutputDebugString
        ('es kann keine Verbindung zur Datenbank hergestellt werden');
    end;
  finally
    Screen.Cursor := crDefault;
    // disconnect;
    ZQuery1.Close;
    Result := strtoint(res) + 1;
  end;
end;

function Tformdb.insertquery(database: string;
  values: Tdictionary<string, string>): boolean;
var
  query: string;
begin
  Screen.Cursor := crHourGlass;
  query         := createCloze('INSERT INTO ', database, values);
  OutputDebugString(PChar(query));
  Result := exec(query);
  // // query := 'insert into Auftr�ge(Telefonnummer,email, ablesedienst, notizen, abrechnungsende, nutzernummer) values("","","","","","");';
  // if not connect then exit;
  // try
  // ZQuery1.SQL.Text := query;
  // ZQuery1.ExecSQL;
  // Result := true;
  // except
  // on e: exception do OutputDebugString(PChar(e.Message));
  // end;
  // finally
  // Screen.Cursor := crDefault;
  // disconnect;
  // end;
end;

function Tformdb.replacequery(table: string;
  values: Tdictionary<string, string>): boolean;
var
  query: string;
begin
  query  := createCloze('REPLACE INTO', table, values);
  Result := exec(query);
end;

function Tformdb.showquery(query: string): boolean;
var
  help: integer;
begin
  try
    if not connect then exit;
    try
      ZQuery1.SQL.Text := query;
      ZQuery1.Open;
      // DBGrid1.DataSource.DataSet.open;
      help := ZQuery1.RecordCount;
      // showmessage(inttostr(help) + ' ergebnisse');
      // DBGrid1.DataSource := ZQuery1.DataSource;
      formdb.Show;
      Result := true;
    except
      OutputDebugString
        ('es kann keine Verbindung zur Datenbank hergestellt werden');
      Result := false;
    end;
  finally
    // ZQuery1.Close;
    // DBGrid1.DataSource.DataSet.Close;
    // disconnect;
  end;
end;

function Tformdb.update(id, table, key, value: string): boolean;
var
  query: string;
begin
  try
    queryupdate.SQL.Clear;
    queryupdate.SQL.Text := 'UPDATE ' + table + ' SET ' + key +
      ' = :value WHERE id = :id';
    queryupdate.ParamByName('value').AsString := value;
    queryupdate.ParamByName('id').AsInteger   := strtoint(id);
    queryupdate.ExecSQL;
    Result := true;
  except
    on e: exception do begin
      OutputDebugString(PChar(e.Message));
      Result := false;

    end;
  end;
  // query := 'UPDATE ' + table + ' SET ' + key + ' = ' + QuotedStr(value) +
  // ' WHERE id = ' + id;
  /// /  showmessage(SQL);
  // queryupdate.SQL.Clear;
  // queryupdate.SQL.Text := query;
  // try
  // queryauftr�ge.ExecSQL;
  // REsult := true;
  // except
  // Result := false;
  // end;
end;

end.
