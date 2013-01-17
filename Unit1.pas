unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, md5, Math, CRCunit, Gauges, ShellAPI;

type
  TForm1 = class(TForm)
    redt1: TRichEdit;
    btn1: TButton;
    btn2: TButton;
    dlgOpen1: TOpenDialog;
    btn3: TButton;
    lbl1: TLabel;
    lbl2: TLabel;
    chk1: TCheckBox;
    lbl3: TLabel;
    g1: TGauge;
    grp1: TGroupBox;
    trckbr1: TTrackBar;
    lbl4: TLabel;
    lbl5: TLabel;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TCoordRec = record
    Horizontal: Integer;
    Vertical: Integer;
  end;

type
  TCompRes = record
    Match: Integer;
    XShift: Integer;
    YShift: Integer;
  end;

type
  TCount = record
    Count: Integer;
    Sign: Integer;
  end;

type
  TArrInfo = record
    Hmax: Integer;
    Hmin: Integer;
    Vmax: Integer;
    Vmin: Integer;
    X: Integer;
    Y: Integer;
    S: string;
  end;

type
  vdir = record
    name: string;
    files: array of array of string;
    match: array of Integer;
  end;

type
  HashType = (tCRC, tMD5);

type
  TSArray = array of array of string;
  TGetDirSizeCallback = procedure(Tag: Integer; CurrentSize: Int64);

var
  Form1: TForm1;
  dPath, wPath: string;
  listWDir: array of string;
  listS: array of string;
  arrF1: TSArray;
  arrF2: TSArray;
  bf2: TArrInfo;

implementation

{$R *.dfm}

procedure GetDirSize(Dir: string; IncludeSubDirs: Boolean; var Result: Int64;
  CallbackProc: TGetDirSizeCallback = nil; CallbackTag: Integer = 0); overload;
var
  SearchRec: TSearchRec;
  FindResult: Integer;
  sz: Int64;
begin
  sz := 0;
  Dir := IncludeTrailingPathDelimiter(Dir);
  FindResult := FindFirst(Dir + '*.*', faAnyFile, SearchRec);
  try
    while FindResult = 0 do
      with SearchRec do
      begin
        if (Attr and faDirectory) <> 0 then
        begin
          if IncludeSubDirs and (Name <> '.') and (Name <> '..') then
            GetDirSize(Dir + Name, IncludeSubDirs, Result, CallbackProc,
              CallbackTag);
        end
        else
        begin
          sz := sz + Size;
          if Assigned(CallbackProc) then
            CallbackProc(CallbackTag, Result);
        end;
        FindResult := FindNext(SearchRec);
      end;
  finally
    FindClose(SearchRec);
  end;
  Result := sz;
end;

function GetDirSize(Dir: string; IncludeSubDirs: Boolean = True): Int64;
  overload;
begin
  GetDirSize(Dir, IncludeSubDirs, Result, nil, 0);
end;

//Функция записи в лог.
function SendLog(Text1: string; Text2: string; Color: TColor; nline: Integer):
  Boolean;
begin
  //if Color = '' then Color:= clBlack;
  Form1.redt1.SelAttributes.Color := Color;
  if nline <> 0 then Form1.redt1.Lines.Add('');
  if Text1 <> '' then Form1.redt1.Lines.Add(Text1);
  Form1.redt1.SelAttributes.Color := clBlack;
  if Text2 <> '' then Form1.redt1.Lines.Add(Text2);
  Result := True;
end;

// Удаление папки.
function eraseD(Dir: string): Integer;
var
  ddtr: TSHFileOpStruct;
begin
  ZeroMemory(@ddtr, SizeOf(ddtr));
  with ddtr do
  begin
    wFunc := FO_DELETE;
    fFlags := FOF_NOCONFIRMATION or FOF_SILENT;
    pFrom := PChar(wPath + '\' + Dir + #0);
  end;
  if SHFileOperation(ddtr) <> 0 then
  begin
    Result := 1;
    RaiseLastOSError;
  end
  else
    Result := 0;
end;

//Убираем весь текст после последнего символа "\"
function PNFN(Text: string): string;
var
  S, I: Integer;
  B: string;
begin
  I := Length(Text) - 1;
  while Text[I] <> '\' do
    I := I - 1;
  for S := 1 to I do
    B := B + Text[S];
  Result := B;
end;

//Выбор типа и подсчёт контрольной суммы.
function hashcalc(fName: string): string;
begin
  case form1.chk1.State of
    cbUnchecked: Result := IntToHex(GetFileCRC(fName), 8);
    cbChecked: Result := MD5DigestToStr(MD5File(fName));
  end;
end;

//Получение координат из имени файла.
function getFCoord(FileName: string): TCoordRec;
var
  tR: TCoordRec;
  i: Integer;
  bf1: string;
begin
  bf1 := '';
  for i := 6 to Length(FileName) do
  begin
    if (FileName[i] <> '_') and (FileName[i] <> '.') then bf1 := bf1 + FileName[i];
    if FileName[i] = '_' then
    begin
      tR.Horizontal := StrToInt(bf1);
      bf1 := '';
    end;
    if FileName[i] = '.' then
    begin
      tR.Vertical := StrToInt(bf1);
      bf1 := '';
    end;
  end;
  Result := tR;
end;

//Проверка папки на наличие нужных файлов и не пустая ли она.
function check_eDir(dirname: string): Integer;
var
  sr2, ff: TSearchRec;
  noempty: Boolean;
  tile: Boolean;
begin
  noempty := False;
  tile := False;
  if FindFirst(wPath + dirname + '\*', faAnyFile, sr2) = 0 then
  begin
    repeat
      if (sr2.Attr <> 0) then
      begin
        if (sr2.Name <> '.') and (sr2.Name <> '..') then
        begin
          noempty := True;
          if FindFirst(wPath + dirname + '\tile_*_*.png', faAnyFile, ff) = 0 then tile := True;
          FindClose(ff);
        end;
      end;
    until ((FindNext(sr2) <> 0) or (noempty) or (tile));
    FindClose(sr2);
  end;

  // если 0 - папка содержит файлы попадающие под маску 'tile_*_*.png'
  // если 1 - папка содержит файлы не попадающие под маску 'tile_*_*.png'
  // если 2 - папка пуста
  if (noempty) then
  begin
    if (tile) then
    begin
      Result := 0;
    end
    else Result := 1;
  end
  else Result := 2;
end;

//Подсчёт количества папок в выбранной папке.
function countDir(s: Integer): Integer;
var
  sr1: TSearchRec;
  cdir: Integer;
begin
  cdir := 0;
  if FindFirst(wPath + '*', faAnyFile, sr1) = 0 then
  begin
    if Form1.trckbr1.Position = 3 then SendLog('Список папок: ', '', clBlue, 1);
    repeat
      if (sr1.Attr and faDirectory) <> 0 then
      begin
        if (sr1.Name <> '.') and (sr1.Name <> '..') then
        begin
          cdir := cdir + 1;
          if Form1.trckbr1.Position = 3 then SendLog('', sr1.Name, clBlack, 0);
        end;
      end;
    until FindNext(sr1) <> 0;
    FindClose(sr1);
  end;
  case s of
    0: SendLog('Папки для поиска тайлов: ', IntToStr(cdir), clGreen, 1);
    1: SendLog('Количество подпапок: ', IntToStr(cdir), clGreen, 1);
  end;
  Result := cdir;
end;

//Подсчёт количества чисел между двумя заданными.
//(хрень ... переделать)
function getCount(n1: Integer; n2: Integer): TCount;
var
  i, j: Integer;
  k: TCount;
begin
  k.Count := 0;
  k.Sign := 1;
  if ((n2 <> -2147483647) and (n2 <> 2147483647)) then
  begin
    if n1 > n2 then
    begin
      if (n1 > n2) then
        k.Sign := -1
      else
        k.Sign := 1;
      j := n1;
      n1 := n2;
      n2 := j;
    end;
    for i := n1 to n2 do
    begin
      k.Count := k.Count + 1;
      Form1.lbl3.Caption := IntToStr(n1) + ' x ' + IntToStr(n2);
      Application.ProcessMessages;
    end;
  end;
  Result := k;
end;

//Расчёт параметров массива из выбранной папки,
// и проверка корректной нумерации.
function calcArr(dirname: string): TArrInfo;
var
  i, cf, c, c1, c2: Integer;
  sr2: TSearchRec;
  bf1: string;
begin
  cf := 0;
  bf2.Vmax := -2147483647;
  bf2.Vmin := 2147483647;
  bf2.Hmax := -2147483647;
  bf2.Hmin := 2147483647;
  bf2.X := 0;
  bf2.Y := 0;
  bf2.S := '';
  if FindFirst(wPath + dirname + '\tile_*_*.png', faAnyFile, sr2) = 0 then
  begin
    repeat
      if sr2.Attr <> 0 then
      begin
        bf1 := '';
        Inc(cf);
        for i := 6 to Length(sr2.name) do
        begin
          if (sr2.Name[i] <> '_') and (sr2.Name[i] <> '.') then bf1 := bf1 + sr2.Name[i];
          if sr2.Name[i] = '_' then
          begin
            if bf2.Hmax < StrToInt(bf1) then
              bf2.Hmax := StrToInt(bf1);
            if bf2.Hmin > StrToInt(bf1) then
              bf2.Hmin := StrToInt(bf1);
            bf1 := '';
          end;
          if sr2.Name[i] = '.' then
          begin
            if bf2.Vmax < StrToInt(bf1) then
              bf2.Vmax := StrToInt(bf1);
            if bf2.Vmin > StrToInt(bf1) then
              bf2.Vmin := StrToInt(bf1);
            bf1 := '';
          end;
        end;
      end;
    until FindNext(sr2) <> 0;
    FindClose(sr2);
  end;
  c1 := getCount(bf2.Hmin, bf2.Hmax).Count;
  c2 := getCount(bf2.Vmin, bf2.Vmax).Count;
  c := (c1 + c2 - 1);
  if cf < c then
    bf2.S := 'ERROR'
  else
    bf2.S := IntToStr(cf);
  Result := bf2;
end;

//Создание массива содержащего список папок для обработки.
function getlistDir(): Integer;
var
  sr3: TSearchRec;
  i, j: Integer;
  r, szp: string;
  sz: Int64;
begin
  i := 0;
  if FindFirst(wPath + '*', faAnyFile, sr3) = 0 then
  begin
    repeat
      if (sr3.Attr and faDirectory) <> 0 then
      begin
        if (sr3.Name <> '.') and (sr3.Name <> '..') then
        begin
          if (check_eDir(sr3.Name) = 0) then
          begin
            r := calcArr(sr3.Name).S;
            if (bf2.Hmin <> 2147483647) then
            begin
              if r = 'ERROR' then
              begin
                SendLog(sr3.Name + ': ', 'Возможно не верное количество тайлов !', clRed, 1);
              end
              else
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog(sr3.Name + ': ', 'Размер: ' + IntToStr(getCount(bf2.Hmin, bf2.Hmax).Count) + ' x ' +
                    IntToStr(getCount(bf2.Vmin, bf2.Vmax).Count) + '  (' + r + '  физически.)', clBlue, 1);
                listWDir[i] := sr3.Name;
                Inc(i);
              end;
              if (Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3) then
              begin
                SendLog('', 'X: от ' + IntToStr(bf2.Hmin) + ' до ' + IntToStr(bf2.Hmax), clBlack, 0);
                SendLog('', 'Y: от ' + IntToStr(bf2.Vmin) + ' до ' + IntToStr(bf2.Vmax), clBlack, 0);
              end;
            end;
          end;
          if (check_eDir(sr3.Name) = 2) then
          begin
            SendLog('Папка ' + sr3.Name + ' пуста, удаляем ... ', '', $00FF8000, 0);
            eraseD(sr3.Name);
          end;  
        end;
      end;
    until FindNext(sr3) <> 0;
    FindClose(sr3);
  end;
  if i > 0 then
  begin
    SetLength(listWDir, i);
    SendLog('Анализируем папки - ' + IntToStr(i) + ' шт. : ', '', clGreen, 1);
    for j := 0 to i - 1 do
    begin
      sz := GetDirSize(IncludeTrailingPathDelimiter(wPath)+listWDir[j], True);
      case sz of
        0..1023: szp := 'byte';
        1024..1048575:
          begin
            szp := 'Kb';
            sz := Round(sz/1024);
          end;
        1048576..1073741823:
          begin
            szp := 'Mb';
            sz := Round(sz/1048576);
          end;
      else
        begin
          szp := 'Gb';
          sz := Round(sz/1073741824);
        end;
      end;
      SendLog('', listWDir[j] + '   ' + IntToStr(sz) + ' ' + szp, clBlack, 0);
    end;
  end;
  Result := 0;
end;

//Заполнение массива именами файлов
//и их контрольными суммами из выбранной папки.
function fillArray(DirName: string; var wArray: TSArray): Integer;
var
  sr6: TSearchRec;
  i, L: integer;
begin
  //SetLength(wArray, 1, 2);
  L := 0;
  if FindFirst(wpath + DirName + '\tile_*_*.png', faAnyFile, sr6) = 0 then
  begin
    repeat
      if sr6.Attr <> 0 then
      begin
        if L = 0 then
        begin
          SetLength(wArray, 1, 2);
          wArray[0, 0] := '';
          wArray[0, 1] := '';
        end
        else
          SetLength(wArray, L + 1, 2);
        L := Length(wArray);
        wArray[L - 1, 0] := sr6.Name;
        wArray[L - 1, 1] := hashcalc(wpath + DirName + '\' + sr6.Name);
        Application.ProcessMessages;
      end;
    until FindNext(sr6) <> 0;
    FindClose(sr6);
  end;
  if Form1.trckbr1.Position = 3 then
  begin
    SendLog('Массив:', DirName, clBlue, 1);
    for i := 0 to Length(wArray) - 1 do
    begin
      SendLog('', 'Имя: ' + wArray[i, 0] + '   Контрольная сумма: ' + wArray[i, 1], clBlack, 0);
    end;
  end;
  Result := Length(wArray);
end;

//Совмещение двух папок с заданным смещением тайлов.
function merge2Dir(Dest: string; Source: string; oH: Integer; oV: Integer; SCopy: Boolean): Integer;
var
  //  j: Integer;
  sr7: TSearchRec;
  fd, fs: string;
  r: Integer;
  os: TCoordRec;
  c: LongBool;
begin
  r := -1;
  try
    //r := -1;
    if (SCopy = True) then
    begin
      if FindFirst(Source + '\tile_*_*.png', faAnyFile, sr7) = 0 then
      begin
        repeat
          if sr7.Attr <> 0 then
          begin
            fs := sr7.Name;
            fd := fs;
            if (FileExists(Dest + '\' + fd)) then
            begin
              if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                SendLog('Пытаемся заменить файл: ', fd, clRed, 1);
              if (Form1.trckbr1.Position = 3) then SendLog('', Source + '\' + fs + ' >>> ' + Dest + '\' + fd, clBlack, 0);
              c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, null);
              if c then
              begin
                SendLog('Заменили ...', '', clGreen, 0);
                if r <> 0 then r := 1;
              end
              else
              begin
                SendLog('Заменть не удалось :( ...', '', clRed, 0);
                r := 0;
              end;
            end
            else
            begin
              SendLog('Пытаемся скопировать файл: ', fs + ' >>> ' + fd, clGreen, 1);
              if (Form1.trckbr1.Position = 3) then SendLog('', Source + '\' + fs + ' >>> ' + Dest + '\' + fd, clBlack, 0);
              c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS);
              if c then
              begin
                SendLog('Скопировали ...', '', clGreen, 0);
                if r <> 0 then r := 1;
              end
              else
              begin
                SendLog('Скопировать не получилось :( ...', '', clRed, 0);
                r := 0;
              end;

            end;
            Application.ProcessMessages;
          end;
        until FindNext(sr7) <> 0;
        FindClose(sr7);
      end;
    end
    else
    begin
      //      if not DirectoryExists(Dest) then
      //        if not CreateDir(Dest) then
      //          raise Exception.Create('Cannot create ' + Dest);
      if FindFirst(Source + '\tile_*_*.png', faAnyFile, sr7) = 0 then
      begin
        repeat
          if sr7.Attr <> 0 then
          begin
            fs := sr7.Name;
            os := getFCoord(fs);
            fd := 'tile_' + IntToStr(os.Horizontal - oH) + '_' + IntToStr(os.Vertical - oV) + '.png';
            if (FileExists(Dest + '\' + fd)) then
            begin
              if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                SendLog('Пытаемся заменить файл: ', fd, clRed, 1);
              if (Form1.trckbr1.Position = 3) then
                SendLog('', '(' + fs + ' [' + DateTimeToStr(FileDateToDateTime(FileAge(Source + '\' + fs))) + '] ' + ' >>> ' +
                  fd
                  + ' [' + DateTimeToStr(FileDateToDateTime(FileAge(Dest + '\' + fd))) + '] ' + ')', clBlack, 0);
              if (FileAge(Source + '\' + fs) > FileAge(Dest + '\' + fd)) then
              begin
                c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, 0);
                if c then
                begin
                  if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                    SendLog('Заменили ...', '', clGreen, 0);
                  if r <> 0 then r := 1;
                end
                else
                begin
                  if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                    SendLog('Заменть не удалось :( ...', '', clRed, 0);
                  r := 0;
                end;

              end
              else
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog('Есть более новый, не копируем.', '', clGreen, 0);
                if r <> 0 then r := 1;
              end;
            end
            else
            begin
              if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                SendLog('Пытаемся скопировать файл: ', fs + ' >>> ' + fd, clGreen, 1);
              if (Form1.trckbr1.Position = 3) then SendLog('', '(' + fs + ' >>> ' + fd + ')', clBlack, 0);
              c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS);
              if c then
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog('Скопировали ...', '', clGreen, 0);
                if r <> 0 then r := 1;
              end
              else
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog('Скопировать не получилось :( ...', '', clRed, 0);
                r := 0;
              end;

            end;
            Application.ProcessMessages;
          end;
        until FindNext(sr7) <> 0;
        FindClose(sr7);
      end;
    end;
  finally
    Result := r;
  end;
end;

//Поиск совпадений (с использованием массивов)
function compDir2(DirName1: string; Fill1: Boolean; DirName2: string; MCount: Integer): TCompRes;
var
  Err, b, m, i, j: Integer;
  f1, f2: TCoordRec;
  shiftX, shiftY: TCount;
  shiftX2, shiftY2: TCount;
begin
  m := 0;
  shiftX.Count := 0;
  shiftY.Count := 0;
  shiftX.Sign := 1;
  shiftY.Sign := 1;
  shiftX2.Count := 0;
  shiftY2.Count := 0;
  shiftX2.Sign := 1;
  shiftY2.Sign := 1;
  try
    if (DirName1 <> '') and (Fill1 = True) then fillArray(DirName1, arrF1);
    if (DirName2 <> '') then fillArray(DirName2, arrF2);
    Err := 0;
    b := 0;
    //    m := 0;
    //    shiftX := 0;
    //    shiftY := 0;
    SendLog('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<', '', clRed, 1);
    SendLog('Сравниваем: ', DirName1 + ' с ' + DirName2, clRed, 1);
    for i := 0 to Length(arrF1) - 1 do
    begin
      b := b + 1;
      Form1.lbl1.Caption := 'Файлы = ' + IntToStr(b);
      for j := 0 to Length(arrF2) - 1 do
      begin
        if (m > MCount-1) then Break;
        if (arrF1[i, 1] = arrF2[j, 1]) then
        begin
          f1 := getFCoord(arrF1[i, 0]);
          f2 := getFCoord(arrF2[j, 0]);
          shiftX2 := getCount(f1.Horizontal, f2.Horizontal);
          shiftY2 := getCount(f1.Vertical, f2.Vertical);
          if m > 0 then
          begin
            if (shiftX.Count <> shiftX2.Count - 1) or (shiftY.Count <> shiftY2.Count - 1) then
            begin
              Err := 1;
              SendLog('Смещение: X=' + IntToStr((shiftX2.Count - 1) * shiftX2.Sign) + ' Y=' + IntToStr((shiftY2.Count - 1) *
                shiftY2.Sign), '', clBlack, 0);
            end;
          end;
          shiftX := getCount(f1.Horizontal, f2.Horizontal);
          shiftY := getCount(f1.Vertical, f2.Vertical);
          shiftX.Count := shiftX.Count - 1;
          shiftY.Count := shiftY.Count - 1;
          if Form1.trckbr1.Position = 3 then
          begin
            SendLog('File1: ', arrF1[i, 0] + '  ' + arrF1[i, 1], clBlue, 1);
            SendLog('File2: ', arrF2[j, 0] + '  ' + arrF2[j, 1], clBlue, 0);
            SendLog('', 'Смещение: X=' + IntToStr(shiftX.Count * shiftX.Sign) + ' Y=' + IntToStr(shiftY.Count *
              shiftY.Sign), clBlack, 0);
          end;
          m := m + 1;
          Form1.lbl2.Caption := 'Совпадения: ' + IntToStr(m);
          Application.ProcessMessages;
        end;
      end;
    end;
    if m > 0 then
    begin
      if Err = 0 then
      begin
        SendLog('', 'Смещение: X=' + IntToStr(shiftX.Count * shiftX.Sign) + ' Y=' + IntToStr(shiftY.Count * shiftY.Sign),
          clBlack, 0);
        SendLog('Найдено совпадающих тайлов: ' + IntToStr(m), '', clBlue, 0);
      end
      else
      begin
        SendLog('Ошибка! У тайлов разное смещение!', '', clRed, 0);
        m := -1;
      end;
    end;
  finally
    Result.Match := m;
    Result.XShift := shiftX.Count * shiftX.Sign;
    Result.YShift := shiftY.Count * shiftY.Sign;
  end;
end;

// Сброс полос прогресса в ноль.
procedure resetG;
begin
  Form1.g1.MinValue := 0;
  Form1.g1.Progress := 0;
  Form1.g1.ForeColor := clNavy;
end;

// Выбор рабочей папки.
procedure TForm1.btn1Click(Sender: TObject);
begin
  resetG;
  dlgOpen1.Execute;
  if dlgOpen1.Files.Text <> '' then
  begin
    wPath := PNFN(dlgOpen1.Files.Text);
    SendLog('Рабочая папка: ', '"' + wPath + '"', clGreen, 1);
    dPath := PNFN(dlgOpen1.Files.Text);
    countDir(1);
    btn1.Caption := 'Work Dir (Selected)';
  end;
end;

// Выбор рабочей папки при создании формы.
procedure TForm1.FormCreate(Sender: TObject);
begin
  redt1.Clear;
  wPath := GetCurrentDir() + '\';
  SendLog('Рабочая папка: ', '"' + wPath + '"', clGreen, 1);
  dpath := GetCurrentDir() + '\';
  countDir(1);
end;

//Количество комбинаций
function comb(n: Integer): Integer;
var
  f: Integer;
  i: Integer;
begin
  f := 0;
  for i := 1 to n do
    f := f + (n- i);
  Result := f;
end;

//Основная процедура
procedure TForm1.btn2Click(Sender: TObject);
var
  i, j, l, mkm, merge, mx: Integer;
  f1, mkmp: Integer;
  compare: TCompRes;
  //dir1, dir2: string;
begin
  try
    redt1.SetFocus;
    SetLength(listWDir, countDir(0));
    resetG;
    getlistDir();
    f1 := -1;
    mkmp := -1;
    l := Length(listWDir);
    mx := l;
    g1.MaxValue := comb(l);
    lbl5.Caption := IntToStr(g1.MaxValue) + ' / ' + IntToStr(g1.Progress);
    if ((l - 1) > 2) then
    begin
      SendLog('Размер массива:', IntToStr(l), clBlue, 1);
      for i := 0 to l - 1 do
      begin
        if (listWDir[i] <> '') then
        begin
          repeat
            mkm := 0;
            for j := (i+1) to l - 1 do
            begin
              if (listWDir[j] <> '') then
              begin
                g1.Progress := g1.Progress + 1;
                lbl5.Caption := IntToStr(comb(l)) + '(' + IntToStr(comb(mx)) + ')' + ' / ' + IntToStr(g1.Progress);
                compare.Match := 0;
                compare.XShift := 0;
                compare.YShift := 0;
                //dir1 := listWDir[i];
                //dir2 := listWDir[j];
                if ((f1 = i) and (mkmp = mkm)) then
                begin
                  compare := compDir2(listWDir[i], False, listWDir[j], 3);
                end
                else
                begin
                  compare := compDir2(listWDir[i], True, listWDir[j], 3);
                end;
                f1 := i;
                mkmp := mkm;
                if (compare.Match > 0) then
                begin
                  SendLog('Совмещаем ', listWDir[i] + ' с ' + listWDir[j], clBlack, 0);
                  merge := merge2Dir(listWDir[i], listWDir[j], compare.XShift, compare.YShift, False);
                  if (merge <> -1) and (merge <> 0) then
                  begin
                    SendLog('Данные перенесены успешно, удаляем директорию '+listWDir[j], '', $00FF8000, 0);
                    eraseD(listWDir[j]);
                    listWDir[j] := '';
                    mkm := mkm + 1;
                    mx := mx-1;
                    g1.MaxValue := comb(mx)+g1.Progress;
                  end;
                end
                else
                begin
                  SendLog('Совпадений нет.', '', $00FF8000, 0);
                end;  
              end;
              Application.ProcessMessages;
            end;
          until mkm = 0;
        end;
        Application.ProcessMessages;
      end;
    end;
    g1.ForeColor := clGreen;
  finally
    SetLength(arrF1, 1, 1);
    SetLength(arrF2, 1, 1);
    //SetLength(listWDir, 1);
    SetLength(listS, 1);
    g1.Progress := g1.MaxValue;
    SendLog('Совмещение папок закончено.', '', $00168000, 1);
  end;
end;

procedure TForm1.btn3Click(Sender: TObject);
begin
  redt1.Clear;
end;

end.

