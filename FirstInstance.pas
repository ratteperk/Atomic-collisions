uses GraphABC, ABCObjects, System.Drawing;

type
  Particle = class
    x, y: real;
    vx, vy: real;
    r: integer;
    mass: real;
    circle: CircleABC;
    rdiff: real;

    constructor Create(ax, ay, avx, avy: real; ar: integer; acolor: Color; amass: real);
    begin
      x := ax; y := ay;
      vx := avx; vy := avy;
      r := ar;
      mass := amass;
      rdiff := 0;
      circle := new CircleABC(Round(x), Round(y), r, acolor);
    end;

    procedure Move;
    begin
      x += vx;
      y += vy;
      //write(' (', x, ',', y, ') ');

      if ((x < 0) and (vx < 0)) or ((x + 2*r > Window.Width) and (vx > 0)) then vx := -vx;
      if ((y < 0) and (vy < 0)) or ((y + 2*r > Window.Height) and (vy > 0)) then vy := -vy;

      circle.MoveTo(Round(x), Round(y));
    end;

    procedure CheckCollision(p: Particle);
    var
      dx, dy, dist, nx, ny, tx, ty, dpTan, dpNorm1, dpNorm2, m1, m2: real;
    begin
      dx := p.x - x;
      dy := p.y - y;
      dist := sqrt(dx*dx + dy*dy);
      if ((dist <= r + p.r) and (rdiff > dist)) then
      begin
        nx := dx / dist;
        ny := dy / dist;
        tx := -ny;
        ty := nx;

        dpTan := vx * tx + vy * ty;
        dpNorm1 := vx * nx + vy * ny;
        dpNorm2 := p.vx * nx + p.vy * ny;

        m1 := (dpNorm1 * (mass - p.mass) + 2 * p.mass * dpNorm2) / (mass + p.mass);
        m2 := (dpNorm2 * (p.mass - mass) + 2 * mass * dpNorm1) / (mass + p.mass);

        vx := tx * dpTan + nx * m1;
        vy := ty * dpTan + ny * m1;
        p.vx := tx * dpTan + nx * m2;
        p.vy := ty * dpTan + ny * m2;
      end;
      rdiff := dist;
    end;
  end;

const
  N = 2;
  Radius = 30;

var
  particles: array[1..N] of Particle;
  speeds: array[1..N] of real;
  angles: array[1..N] of real;
  angle: real;

begin

  writeln('Введите начальные параметры частиц:');
  for var i := 1 to N do
  begin
    write('Скорость частицы ', i, ' (в м/с): ');
    readln(speeds[i]);
    writeln(speeds[i]);
    write('Угол начала движения ', i, ' (в градусах): ');
    readln(angle);
    angles[i] := angle * (Pi / 180);
    writeln(angle);
  end;
  
  SetWindowSize(800, 600);
  SetWindowCaption('Моделирование столкновений частиц');

  for var i := 1 to N do
  begin
    var x := (i = 1)? Window.Width div 4 : Window.Width - Window.Width div 4;
    var y := Window.Height div 2;
    var vx := speeds[i] * cos(angles[i]);
    var vy := speeds[i] * sin(angles[i]);
    var clr := Color.FromArgb(Random(256), Random(256), Random(256));
    particles[i] := new Particle(x, y, vx, vy, Radius, clr, 1.0);
  end;

  while true do
  begin
    for var i := 1 to N do
      particles[i].Move;

    for var i := 1 to N - 1 do
      for var j := i + 1 to N do
        particles[i].CheckCollision(particles[j]);

    Sleep(5);
  end;
end.
