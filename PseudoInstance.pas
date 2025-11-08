uses GraphABC, ABCObjects, System.Drawing;

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
    cx, cy, vx, vy, angle, mass, inertia, rad: real;

    constructor Create(x, y, vx_, vy_: real; a_angle: real; count: integer; r: integer; clr: Color);
    begin
      SetLength(atoms, count);
      mass := count;
      angle := a_angle;
      rad := r;

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

    function MoveAndCheckWallHit: boolean;
    begin
      cx += vx;
      cy += vy;

      foreach var a in atoms do
        a.SetGlobalPosition(cx, cy, angle);

      foreach var a in atoms do
      begin
        var (gx, gy) := a.GlobalPosition(cx, cy, angle);
        if (gx  < 0) or (gx > Window.Width) or
           (gy  < 0) or (gy > Window.Height) then
        begin
          Result := true;
          exit;
        end;
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
            end;
          end;
        end;
      end;
    end;
  end;

const
  Radius = 25;

var
  mols: array[0..1] of Molecule;
  traj: array[0..1] of array of MyPoint;
  count: integer;
  collided := false;

procedure AddPointToTrajectory(var t: array of MyPoint; x, y: integer);
begin
  var len := Length(t);
  SetLength(t, len + 1);
  t[len].x := x;
  t[len].y := y;
end;

begin
  SetWindowSize(800, 600);
  SetWindowCaption('Молекулы: траектории и столкновения');

  count := ReadInteger('Введите количество атомов (2 или 3): ');
  if (count < 2) or (count > 3) then count := 2;

  var speed1 := ReadReal('Скорость первой молекулы: ');
  var angle1 := ReadReal('Угол поворота первой молекулы (в градусах): ') * Pi / 180;

  var speed2 := ReadReal('Скорость второй молекулы: ');
  var angle2 := ReadReal('Угол поворота второй молекулы (в градусах): ') * Pi / 180;

  var vx1 := speed1;
  var vx2 := -speed2;

  mols[0] := new Molecule(200, 300, vx1, 0.0, angle1, count, Radius, clRed);
  mols[1] := new Molecule(600, 300, vx2, 0.0, angle2, count, Radius, clBlue);

  SetLength(traj[0], 0);
  SetLength(traj[1], 0);

  while not collided do
  begin
    for var i := 0 to 1 do
    begin
      if mols[i].MoveAndCheckWallHit then
        collided := true;

      AddPointToTrajectory(traj[i], Round(mols[i].cx), Round(mols[i].cy));
    end;

    mols[0].CheckCollision(mols[1]);

    Sleep(20);
  end;

  ClearWindow;

  SetPenColor(clRed);
  for var i := 1 to High(traj[0]) do
    Line(traj[0][i - 1].x, traj[0][i - 1].y, traj[0][i].x, traj[0][i].y);

  SetPenColor(clBlue);
  for var i := 1 to High(traj[1]) do
    Line(traj[1][i - 1].x, traj[1][i - 1].y, traj[1][i].x, traj[1][i].y);
end.
