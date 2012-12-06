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
    chk2: TCheckBox;
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
//������� ������ � ���.
function SendLog(Text1: string; Text2: string; Color: TColor; nline: Integer):
  Boolean;
begin
  //if Color = '' then Color:= clBlack;
  Form1.redt1.SelAttributes.Color := Color;
  if nline <> 0 then Form1.redt1.Lines.Add('');
  if Text1 <> '' then Form1.redt1.Lines.Add(Text1);
  if Text2 <> '' then Form1.redt1.Lines.Add(Text2);
  Result := True;
end;

//������� ��������� ������ "\" �� ������
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

//����� ���� � ������� ����������� �����.
function hashcalc(fName: string): string;
begin
  case form1.chk1.State of
    cbUnchecked: Result := IntToHex(GetFileCRC(fName), 8);
    cbChecked: Result := MD5DigestToStr(MD5File(fName));
  end;
end;

//��������� ��������� �� ����� �����.
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

//������� ���������� ����� � ��������� �����.
function countDir(): Integer;
var
  sr1: TSearchRec;
  cdir: Integer;
begin
  cdir := 0;
  if FindFirst(wPath + '*', faAnyFile, sr1) = 0 then
  begin
    if Form1.trckbr1.Position = 3 then SendLog('������ �����: ', '', clBlue, 1);
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
  SetLength(listWDir, cdir);
  SendLog('����� ��� ������ ������: ', IntToStr(cdir), clGreen, 1);
  Result := cdir;
end;

//������� ���������� ����� ����� ����� ���������.
//(����� ... ����������)
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

//������ ���������� ������� �� ��������� �����,
// � �������� ���������� ���������.
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
  if FindFirst(wpath + dirname + '\tile_*_*.png', faAnyFile, sr2) = 0 then
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

//�������� ������� ����������� ������ ����� ��� ���������.
function getlistDir(): Integer;
var
  sr3: TSearchRec;
  i, j: Integer;
  r: string;
begin
  i := 0;
  if FindFirst(wpath + '*', faAnyFile, sr3) = 0 then
  begin
    repeat
      if (sr3.Attr and faDirectory) <> 0 then
      begin
        if (sr3.Name <> '.') and (sr3.Name <> '..') then
        begin
          r := calcArr(sr3.Name).S;
          if (bf2.Hmin <> 2147483647) then
          begin
            if r = 'ERROR' then
            begin
              SendLog(sr3.Name + ': ', '�������� �� ������ ���������� ������ !', clRed, 1);
            end
            else
            begin
              if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                SendLog(sr3.Name + ': ', '������: ' + IntToStr(getCount(bf2.Hmin, bf2.Hmax).Count) + ' x ' +
                  IntToStr(getCount(bf2.Vmin, bf2.Vmax).Count) + '  (' + r + '  ���������.)', clBlue, 1);
              listWDir[i] := sr3.Name;
              Inc(i);
            end;
            if (Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3) then
            begin
              SendLog('', 'X: �� ' + IntToStr(bf2.Hmin) + ' �� ' + IntToStr(bf2.Hmax), clBlack, 0);
              SendLog('', 'Y: �� ' + IntToStr(bf2.Vmin) + ' �� ' + IntToStr(bf2.Vmax), clBlack, 0);
            end;
          end;
        end;
      end;
    until FindNext(sr3) <> 0;
    FindClose(sr3);
  end;
  if i > 0 then
  begin
    SetLength(listWDir, i);
    SendLog('����������� ����� - ' + IntToStr(i) + ' ��. : ', '', clGreen, 1);
    for j := 0 to i - 1 do
    begin
      SendLog('', listWDir[j], clBlack, 0);
    end;
  end;
  Result := 0;
end;

//���������� ������� ������� ������
//� �� ������������ ������� �� ��������� �����.
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
    SendLog('������:', DirName, clBlue, 1);
    for i := 0 to Length(wArray) - 1 do
    begin
      SendLog('', '���: ' + wArray[i, 0] + '   ����������� �����: ' + wArray[i, 1], clBlack, 0);
    end;
  end;
  Result := Length(wArray);
end;

//���������� ���� ����� � �������� ��������� ������.
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
                SendLog('�������� �������� ����: ', fd, clRed, 1);
              if (Form1.trckbr1.Position = 3) then SendLog('', Source + '\' + fs + ' >>> ' + Dest + '\' + fd, clBlack, 0);
              c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, null);
              if c then
              begin
                SendLog('�������� ...', '', clGreen, 0);
                if r <> 0 then r := 1;
              end
              else
              begin
                SendLog('������� �� ������� :( ...', '', clRed, 0);
                r := 0;
              end;
            end
            else
            begin
              SendLog('�������� ����������� ����: ', fs + ' >>> ' + fd, clGreen, 1);
              if (Form1.trckbr1.Position = 3) then SendLog('', Source + '\' + fs + ' >>> ' + Dest + '\' + fd, clBlack, 0);
              c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS);
              if c then
              begin
                SendLog('����������� ...', '', clGreen, 0);
                if r <> 0 then r := 1;
              end
              else
              begin
                SendLog('����������� �� ���������� :( ...', '', clRed, 0);
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
                SendLog('�������� �������� ����: ', fd, clRed, 1);
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
                    SendLog('�������� ...', '', clGreen, 0);
                  if r <> 0 then r := 1;
                end
                else
                begin
                  if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                    SendLog('������� �� ������� :( ...', '', clRed, 0);
                  r := 0;
                end;

              end
              else
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog('���� ����� �����, �� ��������.', '', clGreen, 0);
                if r <> 0 then r := 1;
              end;
            end
            else
            begin
              if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                SendLog('�������� ����������� ����: ', fs + ' >>> ' + fd, clGreen, 1);
              if (Form1.trckbr1.Position = 3) then SendLog('', '(' + fs + ' >>> ' + fd + ')', clBlack, 0);
              c := CopyFileEx(PChar(Source + '\' + fs), PChar(Dest + '\' + fd), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS);
              if c then
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog('����������� ...', '', clGreen, 0);
                if r <> 0 then r := 1;
              end
              else
              begin
                if ((Form1.trckbr1.Position = 2) or (Form1.trckbr1.Position = 3)) then
                  SendLog('����������� �� ���������� :( ...', '', clRed, 0);
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

//����� ���������� (��� ��������)(������)
function compDir(dirname1: string; dirname2: string): string;
var
  sr4, sr5: TSearchRec;
  hash_1, hash_2: string;
  shiftX, shiftY: Integer;
  f1, f2: TCoordRec;
  c, b, ok: Integer;
begin
  c := 0;
  b := 0;
  ok := 0;
  SendLog('--------------------------------------', '', clRed, 1);
  SendLog('����������: ', dirname1 + ' � ' + dirname2, clRed, 1);
  if FindFirst(wpath + dirname1 + '\tile_*_*.png', faAnyFile, sr4) = 0 then
  begin
    repeat
      if sr4.Attr <> 0 then
      begin
        hash_1 := hashcalc(wpath + dirname1 + '\' + sr4.Name);
        b := b + 1;
        Form1.lbl1.Caption := IntToStr(b);
        if FindFirst(wpath + dirname2 + '\tile_*_*.png', faAnyFile, sr5) = 0 then
        begin
          repeat
            if sr5.Attr <> 0 then
            begin
              hash_2 := hashcalc(wpath + dirname2 + '\' + sr5.Name);
              if hash_2 = hash_1 then
              begin
                f1 := getFCoord(sr4.Name);
                f2 := getFCoord(sr5.Name);
                shiftX := getCount(f1.Horizontal, f2.Horizontal).Count - 1;
                shiftY := getCount(f1.Vertical, f2.Vertical).Count - 1;
                SendLog('', '����_1:  ' + sr4.Name + '  ' + '(' + hash_1 + ')', clBlue, 1);
                SendLog('', '����_2:  ' + sr5.Name + '  ' + '(' + hash_2 + ')', clBlue, 0);
                SendLog('', '��������:  X= ' + IntToStr(shiftX) + '  Y= ' + IntToStr(shiftY), clBlack, 0);
                ok := ok + 1;
              end;
              c := c + 1;
              Form1.lbl2.Caption := IntToStr(c) + ' ok=' + IntToStr(ok);
            end;
          until (FindNext(sr5) <> 0) or (ok > 1);
          FindClose(sr5);
        end;
      end;
      Application.ProcessMessages;
    until (FindNext(sr4) <> 0) or (ok > 1);
    FindClose(sr4);
  end;
end;

//����� ���������� (� �������������� ��������)
function compDir2(DirName1: string; Fill1: Boolean; DirName2: string): TCompRes;
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
    SendLog('����������: ', DirName1 + ' � ' + DirName2, clRed, 1);
    for i := 0 to Length(arrF1) - 1 do
    begin
      b := b + 1;
      Form1.lbl1.Caption := '����� = ' + IntToStr(b);
      for j := 0 to Length(arrF2) - 1 do
      begin
        if (Form1.chk2.State = cbChecked) and (m = 3) then Break;
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
              SendLog('��������: X=' + IntToStr((shiftX2.Count - 1) * shiftX2.Sign) + ' Y=' + IntToStr((shiftY2.Count - 1) *
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
            SendLog('', '��������: X=' + IntToStr(shiftX.Count * shiftX.Sign) + ' Y=' + IntToStr(shiftY.Count *
              shiftY.Sign), clBlack, 0);
          end;
          m := m + 1;
          Form1.lbl2.Caption := '����������: ' + IntToStr(m);
          Application.ProcessMessages;
        end;
      end;
    end;
    if m > 0 then
    begin
      if Err = 0 then
      begin
        SendLog('', '��������: X=' + IntToStr(shiftX.Count * shiftX.Sign) + ' Y=' + IntToStr(shiftY.Count * shiftY.Sign),
          clBlack, 0);
        SendLog('������� ' + IntToStr(m) + ' ����������� ������.', '', clBlue, 0);
      end
      else
      begin
        SendLog('������! � ������ ������ ��������!', '', clRed, 0);
        m := -1;
      end;
    end;
  finally
    Result.Match := m;
    Result.XShift := shiftX.Count * shiftX.Sign;
    Result.YShift := shiftY.Count * shiftY.Sign;
  end;
end;

// �������� �����.
function moveR(Dir: string): Integer;
var
  ddtr: TSHFileOpStruct;
begin
  with ddtr do
  begin
    Wnd := Application.Handle;
    wFunc := FO_DELETE;
    pFrom := PChar(GetCurrentDir + '\' + Dir);
    pTo := nil;
    fFlags := FOF_NOCONFIRMATION or FOF_ALLOWUNDO;
  end;
  if SHFileOperation(ddtr) <> 0 then
  begin
    Result := 1;
    RaiseLastOSError;
  end
  else
    Result := 0;
end;

// ����� ����� ��������� � ����.
procedure resetG;
begin
  Form1.g1.MinValue := 0;
  Form1.g1.Progress := 0;
  Form1.g1.ForeColor := clNavy;
end;

// ����� ������� �����.
procedure TForm1.btn1Click(Sender: TObject);
begin
  resetG;
  dlgOpen1.Execute;
  if dlgOpen1.Files.Text <> '' then
  begin
    wPath := PNFN(dlgOpen1.Files.Text);
    SendLog('������� �����: ', '"' + wPath + '"', clGreen, 1);
    dPath := PNFN(dlgOpen1.Files.Text);
    countDir();
    btn1.Caption := 'Work Dir (Selected)';
  end;
end;

// ����� ������� ����� ��� �������� �����.
procedure TForm1.FormCreate(Sender: TObject);
begin
  redt1.Clear;
  wPath := GetCurrentDir() + '\';
  SendLog('������� �����: ', '"' + wPath + '"', clGreen, 1);
  dpath := GetCurrentDir() + '\';
  countDir();
end;

//�������� ���������
procedure TForm1.btn2Click(Sender: TObject);
var
  i: Integer;
  m: TCompRes;
begin
  try
    resetG;
    getlistDir();
    g1.MaxValue := Length(listWDir) - 1;
    if ((Length(listWDir) - 1) > 0) then
    begin
      SendLog('������ �������:', IntToStr(Length(listWDir)), clBlue, 1);
      for i := 1 to Length(listWDir) - 1 do
      begin
        m.Match := 0;
        m.XShift := 0;
        m.YShift := 0;
        if (listWDir[i] <> '') then
        begin
          //          if (i > 1) then
          //            m := compDir2(listWDir[0], False, listWDir[i])
          //          else
          //            m := compDir2(listWDir[0], True, listWDir[i]);
          //          if (m.Match > 0) then
          //          begin
          //            SendLog('��������� ', listWDir[0] + ' � ' + listWDir[i], clBlack, 0);
          //            e := merge2Dir(listWDir[0], listWDir[i], m.XShift, m.YShift, False);
          //            if (e <> -1) and (e <> 0) then
          //            begin
          //              SendLog('������ ����������, ����� �������.', '', $00FF8000, 0);
          //              moveR(listWDir[i]);
          //            end;
          //          end;
        end;
        g1.Progress := i;
      end;
    end;
    g1.ForeColor := clGreen;
  finally
    SetLength(arrF1, 1, 1);
    SetLength(arrF2, 1, 1);
    //SetLength(listWDir, 1);
    SetLength(listS, 1);
  end;
end;

procedure TForm1.btn3Click(Sender: TObject);
begin
  redt1.Clear;
end;

end.
