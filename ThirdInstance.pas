uses GraphABC, ABCObjects;

type
  MyPoint = record
    x, y: integer;
  end;

  Atom = class
    relX, relY: real;
    r: integer;
    circle: CircleABC;

    constructor Create(ax, ay: real; ar: integer; clr: Color);
    begin
      relX := ax;
      relY := ay;
      r := ar;
      circle := new CircleABC(0, 0, r, clr);
    end;

    procedure SetGlobalPosition(cx, cy, angle: real);
    var gx, gy: real;
    begin
      gx := cx + relX * cos(angle) - relY * sin(angle);
      gy := cy + relX * sin(angle) + relY * cos(angle);
      circle.MoveTo(Round(gx), Round(gy));
    end;

    function GlobalPosition(cx, cy, angle: real): (real, real);
    begin
      Result := (
        cx + relX * cos(angle) - relY * sin(angle),
        cy + relX * sin(angle) + relY * cos(angle)
      );
    end;
  end;

  Molecule = class
    atoms: array of Atom;
    cx, cy, vx, vy, omega, angle, mass, inertia, rad: real;
    clr: Color;

    constructor Create(x, y, vx_, vy_, angle0: real; count: integer; r: integer; clr_: Color);
    begin
      SetLength(atoms, count);
      mass := count;
      angle := angle0;
      omega := 0;
      rad := r;
      clr := clr_;

      if count = 3 then
      begin
        atoms[0] := new Atom(0, -r + 3, r, clr);
        atoms[1] := new Atom(-r, r, r, clr);
        atoms[2] := new Atom(r + 2, r, r, clr);
      end
      else
      begin
        for var i := 0 to count - 1 do
        begin
          var dx := (i - (count - 1)/2) * (2 * r + 2);
          atoms[i] := new Atom(dx, 0, r, clr);
        end;
      end;

      cx := x; cy := y;
      vx := vx_; vy := vy_;

      inertia := 0;
      foreach var a in atoms do
        inertia += sqr(a.relX) + sqr(a.relY);
    end;

    procedure Move;
    begin
      cx += vx;
      cy += vy;
      angle += omega;

      foreach var a in atoms do
        a.SetGlobalPosition(cx, cy, angle);
    end;

    procedure CheckWallCollision;
    begin
      foreach var a in atoms do
      begin
        var (gx, gy) := a.GlobalPosition(cx, cy, angle);
        if (gx < 0) and (vx < 0) or (gx + 2*a.r > Window.Width) and (vx > 0)  then vx := -vx;
        if (gy < 0) and (vy < 0) or (gy + 2*a.r > Window.Height) and (vy > 0) then vy := -vy;
      end;
    end;

    function HitWall: boolean;
    begin
      foreach var a in atoms do
      begin
        var (gx, gy) := a.GlobalPosition(cx, cy, angle);
        if (gx + 2 * a.r < 0) or (gx > Window.Width) or
           (gy < 0) or (gy + 2 * a.r > Window.Height) then
          Exit(true);
      end;
      Result := false;
    end;

    procedure CheckCollision(other: Molecule);
    begin
      foreach var a in atoms do
      begin
        var (ax, ay) := a.GlobalPosition(cx, cy, angle);
        foreach var b in other.atoms do
        begin
          var (bx, by) := b.GlobalPosition(other.cx, other.cy, other.angle);
          var dx := bx - ax;
          var dy := by - ay;
          var dist := sqrt(dx * dx + dy * dy);
          var minDist := a.r + b.r;

          if dist < minDist then
          begin
            var nx := dx / dist;
            var ny := dy / dist;

            var relVx := other.vx - vx;
            var relVy := other.vy - vy;

            var impactSpeed := relVx * nx + relVy * ny;

            if impactSpeed < 0 then
            begin
              var impulse := 2 * impactSpeed / (mass + other.mass);

              vx += impulse * other.mass * nx;
              vy += impulse * other.mass * ny;
              other.vx -= impulse * mass * nx;
              other.vy -= impulse * mass * ny;

              var rx := ax - cx;
              var ry := ay - cy;
              var rPerp := rx * ny - ry * nx;
              omega += (rPerp * impulse) / inertia;

              var orx := bx - other.cx;
              var ory := by - other.cy;
              var orPerp := orx * ny - ory * nx;
              other.omega -= (orPerp * impulse) / other.inertia;
            end;
          end;
        end;
      end;
    end;
  end;

var
  mols: array of Molecule;
  traj: array of array of List<MyPoint>;
  count := 2;
  trackedCount := 2;

begin
  SetWindowSize(800, 600);
  SetWindowCaption('Молекулы с массовкой и траекториями');

  count := ReadInteger('Количество атомов (2 или 3): ');
  if count < 2 then count := 2;
  if count > 3 then count := 3;

  var speed1, angle1, speed2, angle2: real;
  writeln('Скорость первой молекулы: ');
  read(speed1);
  writeln('Начальный угол поворота первой молекулы (в градусах): ');
  read(angle1);
  writeln('Скорость второй молекулы: ');
  read(speed2);
  writeln('Начальный угол поворота второй молекулы (в градусах): ');
  read(angle2);

  angle1 := angle1 * Pi / 180;
  angle2 := angle2 * Pi / 180;

  SetLength(mols, 2 + 10); // 2 отслеживаемых + 10 массовки

  mols[0] := new Molecule(200, 300, speed1, 0, angle1, count, 15, clRed);
  mols[1] := new Molecule(600, 300, -speed2, 0, angle2, count, 15, clBlue);

  // Массовка на заранее известных координатах
  var massCoords := [
    (100,100), (700,100), (400,100), (100,500), (700,500),
    (400,500), (200,200), (600,200), (200,400), (600,400)
  ];

  for var i := 0 to 9 do
    mols[2 + i] := new Molecule(massCoords[i][0], massCoords[i][1], 2 * cos(i), 2 * sin(i), 0, count, 15, clGray);

  // Траектории
  SetLength(traj, trackedCount);
  for var i := 0 to trackedCount - 1 do
  begin
    SetLength(traj[i], count);
    for var j := 0 to count - 1 do
      traj[i][j] := new List<MyPoint>;
  end;

  var stopped := false;

  while not stopped do
  begin
    for var i := 0 to mols.Length - 1 do
    begin
      mols[i].Move;

      if i < trackedCount then
        for var j := 0 to count - 1 do
        begin
          var (gx, gy) := mols[i].atoms[j].GlobalPosition(mols[i].cx, mols[i].cy, mols[i].angle);
          var p: MyPoint;
          p.x := Round(gx);
          p.y := Round(gy);
          traj[i][j].Add(p);
        end;

      if (i < trackedCount) and mols[i].HitWall then
        stopped := true;

      if i >= trackedCount then
        mols[i].CheckWallCollision;
    end;

    // Обработка всех пар
    for var i := 0 to mols.Length - 2 do
      for var j := i + 1 to mols.Length - 1 do
        mols[i].CheckCollision(mols[j]);

    Sleep(10);
  end;

  // Отрисовка траекторий
  ClearWindow;
  SetPenColor(clGreen);
  SetPenWidth(2);
  for var i := 0 to trackedCount - 1 do
    for var j := 0 to count - 1 do
      for var k := 1 to traj[i][j].Count - 1 do
        Line(traj[i][j][k - 1].x, traj[i][j][k - 1].y,
             traj[i][j][k].x, traj[i][j][k].y);
end.
