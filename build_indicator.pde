

class Led {
  public:
    Led(int redPin, int greenPin, int bluePin) 
    {
      r_pin = redPin;
      g_pin = greenPin;
      b_pin = bluePin;
      
      pinMode(r_pin, OUTPUT);
      pinMode(g_pin, OUTPUT);
      pinMode(b_pin, OUTPUT);
    }
      
    void set_color(unsigned int _red, unsigned int _green, unsigned int _blue)
    {
        if (_red > 100) _red = 100;
        if (_green > 100) _green = 100;
        if (_blue > 100) _blue = 100;
        int r = 255 - _red * 255 / 100;
        int g = 255 - _green * 255 / 100;
        int b = 255 - _blue * 255 / 100;
    
        analogWrite(r_pin, r);
        analogWrite(g_pin, g);
        analogWrite(b_pin, b);        
    }
             
    void off() 
    {
        set_color(0, 0, 0);
    }
  private:
    int r_pin;
    int g_pin;
    int b_pin;
};

class Transition
{
  public:
    Transition() 
    {
      started = false;
    }
    
    void set_led(Led* _led)
    {
      led = _led;
    }
    
    void start(unsigned int _r1, unsigned int _g1, unsigned int _b1,
               unsigned int _r2, unsigned int _g2, unsigned int _b2,
               unsigned long _tr_millis)
    {
      r1 = _r1;
      g1 = _g1;
      b1 = _b1;
      r2 = _r2;
      g2 = _g2;
      b2 = _b2;
      tr_millis = _tr_millis;
      restart();
    }
    
    boolean step()
    {
      long t_step = millis() - start_millis;
      started = t_step < tr_millis;      
      if (!started)
          return started;
/*      Serial.print("step [");
      Serial.print(t_step);
      Serial.print(" of ");
      Serial.print(tr_millis);
      Serial.print(", start color:");
      dump_color(r1, g1, b1);
      Serial.print(", end color:");
      dump_color(r2, g2, b2);*/
      long trm = tr_millis;
      long r = r1 + (r2 - r1) * t_step / trm;
      long g = g1 + (g2 - g1) * t_step / trm;
      long b = b1 + (b2 - b1) * t_step / trm;
/*      Serial.print(", current c=");
      dump_color(r, g, b);
      Serial.println("]");*/
      led->set_color(r, g, b);
      return started;
    }

    void restart()
    {
      start_millis = millis();
      started = true;
      step();
    }
    
  private:
    void dump_color(int r, int g, int b) 
    {
      Serial.print("(");
      Serial.print(r);
      Serial.print(",");
      Serial.print(g);
      Serial.print(",");
      Serial.print(b);
      Serial.print(")");
    }
    
  
    Led* led;
    long r1, g1, b1, r2, g2, b2;
    boolean started;
    unsigned long tr_millis;
    unsigned long start_millis;
};

Led led1(3, 5, 6);
Led led2(9, 10, 11);
Transition tr1;
Transition tr2;

const int mode_ok = 1;
const int mode_in_progress = 2;
const int mode_failed = 3;
const int mode_wait = 4;

int current_mode = -1;
int next_mode = 0;

void setup() 
{
  Serial.begin(9600);
  /*
  led1.set_color(100, 0, 0);
  led2.set_color(0, 100, 0);
  delay(25);
  led1.set_color(0, 0, 100);
  led2.set_color(100, 0, 0);
  delay(25);
  led1.set_color(0, 100, 0);
  led2.set_color(0, 0, 100);
  delay(25);*/
  led1.off();
  led2.off();
  current_mode = mode_wait;
  next_mode = mode_wait;
  Serial.print("r");
}

unsigned long mode_started;

void display_wait()
{
  unsigned long d = millis() - mode_started;
  if (d < 100)
  {
    led1.set_color(0, 0, 100);
    led2.set_color(0, 0, 100);
  } 
  else if (d < 1500)
  {
    led1.off();
    led2.off();
  } 
  else 
  {
    mode_started = millis();
  }
}

boolean in_transition = false;

void display_in_progress()
{
  unsigned long d = millis() - mode_started;
  if (d < 1750) 
  {
    in_transition = false;
    led1.set_color(100, 100, 0);
    led2.off();
  }  
  else if (d < 2000)
  {
    if (in_transition) 
    {
      tr1.step();
      tr2.step();
    }
    else 
    {
      tr1.set_led(&led1);
      tr1.start(100, 100, 0, 0, 0, 0, 250);
      tr2.set_led(&led2);
      tr2.start(0, 0, 0, 100, 100, 0, 250);
      in_transition = true;
    }
  }
  else if (d < 3750)
  {
    in_transition = false;
    led1.off();
    led2.set_color(100, 100, 0);    
  }  
  else if (d < 4000)
  {
    if (in_transition) 
    {
      tr1.step();
      tr2.step();
    }
    else 
    {
      tr1.set_led(&led1);
      tr1.start(0, 0, 0, 100, 100, 0, 250);
      tr2.set_led(&led2);
      tr2.start(100, 100, 0, 0, 0, 0, 250);
      in_transition = true;
    }    
  }
  else
  {
    mode_started = millis();
  }
}

boolean swap = false;

void display_fail()
{
  unsigned long d = millis() - mode_started;
  Led* l1;
  Led* l2;
  if (!swap)
  {
    l1 = &led1;
    l2 = &led2;
  } else {
    l1 = &led2;
    l2 = &led1;
  }    
  if (d < 1000) 
  {
    if (in_transition) {
      tr1.step();
    } else {
      tr1.set_led(l1);
      tr1.start(0, 0, 0, 100, 0, 0, 1000);
      in_transition = true;
    }
  } else if (d < 1250) {
    in_transition = false;
    l1->set_color(100, 0, 0);
  } else if (d < 2250) {
    if (in_transition) {
      tr1.step();
    } else {
      tr1.set_led(l1);
      tr1.start(100, 0, 0, 0, 0, 0, 1000);
      in_transition = true;
    }    
  } else if (d < 2500) {
    in_transition = false;
    l1->off();
  }
  int d2 = d / 50 % 20;
  if (d2 == 1 || d2 == 3 || d2 == 11 || d2 == 13) {
    l2->set_color(0, 0, 100);
  } else
    l2->off();
  if (d >= 2500) {
    swap = !swap;
    mode_started = millis();
  }
}

void display_ok()
{
  led1.set_color(0, 100, 0);
  led2.set_color(0, 100, 0);
}

long last_sent = 0;

void loop()
{
  if (current_mode != next_mode)
  {
    mode_started = millis();
    current_mode = next_mode;
  }
  if (millis() - last_sent > 1000) 
  {
    Serial.print('r');
    last_sent = millis();
  }
  switch (current_mode) 
  {
    case mode_wait:
      display_wait();
      break;
    case mode_ok:
      display_ok();
      break;
    case mode_in_progress:
      display_in_progress();
      break;
    case mode_failed:
      display_fail();
      break;
//    default:
//      display_wait();
  }
  int in = Serial.read();
  if (in >= 0) 
  {
    char c = char(in);
    switch (c)
    {
      case '0': next_mode = mode_ok; break;
      case '1': next_mode = mode_in_progress; break;
      case '2': next_mode = mode_failed; break;
      case '3': next_mode = mode_wait;break;
//      default: next_mode = 0; 
    }
  }
}
