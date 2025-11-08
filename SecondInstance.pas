uses GraphABC, ABCObjects, System.Drawing;

type
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

    constructor Create(x, y, vx_, vy_: real; count: integer; r: integer; clr: Color);
    begin
      SetLength(atoms, count);
      mass := count;
      angle := 0;
      omega := 0;
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

    procedure Move;
    begin
      cx += vx;
      cy += vy;
      angle += omega;

      foreach var a in atoms do
        a.SetGlobalPosition(cx, cy, angle);

      foreach var a in atoms do
      begin
        var (gx, gy) := a.GlobalPosition(cx, cy, angle);
        var rx := gx - cx;
        var ry := gy - cy;

        var vx_point := vx - omega * ry;
        var vy_point := vy + omega * rx;

        if (gx < 0) and (vx_point < 0) then
        begin
          var n := (1.0, 0.0);
          var vrel := vx_point * n[0] + vy_point * n[1];
          var r_perp := rx * n[1] - ry * n[0];
          var denom := 1 / mass + sqr(r_perp) / inertia;
          var j := -2 * vrel / denom;
          vx += j * n[0] / mass;
          vy += j * n[1] / mass;
          omega += (r_perp * j) / inertia;
        end
        else if (gx + 2*a.r > Window.Width) and (vx_point > 0) then
        begin
          var n := (-1.0, 0.0);
          var vrel := vx_point * n[0] + vy_point * n[1];
          var r_perp := rx * n[1] - ry * n[0];
          var denom := 1 / mass + sqr(r_perp) / inertia;
          var j := -2 * vrel / denom;
          vx += j * n[0] / mass;
          vy += j * n[1] / mass;
          omega += (r_perp * j) / inertia;
        end;

        if (gy < 0) and (vy_point < 0) then
        begin
          var n := (0.0, 1.0);
          var vrel := vx_point * n[0] + vy_point * n[1];
          var r_perp := rx * n[1] - ry * n[0];
          var denom := 1 / mass + sqr(r_perp) / inertia;
          var j := -2 * vrel / denom;
          vx += j * n[0] / mass;
          vy += j * n[1] / mass;
          omega += (r_perp * j) / inertia;
        end
        else if (gy + 2*a.r > Window.Height) and (vy_point > 0) then
        begin
          var n := (0.0, -1.0);
          var vrel := vx_point * n[0] + vy_point * n[1];
          var r_perp := rx * n[1] - ry * n[0];
          var denom := 1 / mass + sqr(r_perp) / inertia;
          var j := -2 * vrel / denom;
          vx += j * n[0] / mass;
          vy += j * n[1] / mass;
          omega += (r_perp * j) / inertia;
        end;
      end;
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
  mols: array[0..1] of Molecule;

begin
  SetWindowSize(800, 600);
  SetWindowCaption('2 Молекулы: столкновение с вращением');

  var count := ReadInteger('Введите количество атомов (2 или 3): ');
  writeln(count);
  if (count < 2) or (count > 3) then count := 2;
  
  var angle_deg := ReadInteger('Введите угол движения (в градусах): ');
  writeln(angle_deg);
  write('Введите скорость: ');
  var speed : real;
  readln(speed);
  writeln(speed);
  var angle_rad := angle_deg * Pi / 180;

  var vx := speed * cos(angle_rad);
  var vy := speed * sin(angle_rad);

  mols[0] := new Molecule(200, 300, vx, vy, count, 25, clRed);
  mols[1] := new Molecule(600, 300, -vx, -vy, count, 25, clBlue);

  while true do
  begin
    foreach var m in mols do m.Move;

    mols[0].CheckCollision(mols[1]);

    Sleep(10);
  end;
end.
