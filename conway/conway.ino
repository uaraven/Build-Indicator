/*
 * Game Of Life on 8x8 double-colored LED matrix
 */
const int dataPin = 2;
const int clockPin = 3; //12;
const int latchPin = 4; //11;

const int rdata = 8;
const int rclock = 9;
const int rlatch = 10;

const int RED = 0;
const int GREEN = 1;

byte field[8];

void drawField(int color) {
  for (int i = 0; i < 8; i++) 
  {
    int row = 1 << i;
    digitalWrite(rlatch, LOW);
    shiftOut(rdata, rclock, MSBFIRST, 0xFF);
    digitalWrite(rlatch, HIGH);
    
    digitalWrite(latchPin, LOW);
    if (color == RED) {
      shiftOut(dataPin, clockPin, MSBFIRST, 0);       
      shiftOut(dataPin, clockPin, MSBFIRST, field[i]);   
    } else if (color == GREEN) {
      shiftOut(dataPin, clockPin, MSBFIRST, field[i]);      
      shiftOut(dataPin, clockPin, MSBFIRST, 0);             
    } else {
      shiftOut(dataPin, clockPin, MSBFIRST, field[i]);       
      shiftOut(dataPin, clockPin, MSBFIRST, field[i]);      
    }      

    digitalWrite(latchPin, HIGH);
    
    digitalWrite(rlatch, LOW);
    shiftOut(rdata, rclock, MSBFIRST, ~row);
    digitalWrite(rlatch, HIGH);    
//    delayMicroseconds(1000);
  }
}

void happyFace() {
  field[0] = 0b01111110;
  field[1] = 0b10000001;
  field[2] = 0b10100101;
  field[3] = 0b10000001;  
  field[4] = 0b10100101;
  field[5] = 0b10011001;
  field[6] = 0b10000001;
  field[7] = 0b01111110;  
}

void sadFace() {
  field[0] = 0b00111100;
  field[1] = 0b01000010;
  field[2] = 0b10100101;
  field[3] = 0b10000001;  
  field[4] = 0b10011001;
  field[5] = 0b10100101;
  field[6] = 0b01000010;
  field[7] = 0b00111100;  
}

void indifferentFace() {
  field[0] = 0b00111100;
  field[1] = 0b01000010;
  field[2] = 0b10100101;
  field[3] = 0b10000001;  
  field[4] = 0b10000001;
  field[5] = 0b10111101;
  field[6] = 0b01000010;
  field[7] = 0b00111100;  
}

// ------------ Game of Life --------------------
int clamp(int v) {
  if (v < 0) {
    return 7;
  } else if (v > 7) {
    return 0;
  } else {
    return v;
  }  
}  

int getPoint(byte* field, int px, int py) {
  int x = clamp(px);
  int y = clamp(py);
  return bitRead(field[y], x);
}

void setPoint(byte* field, int px, int py) {
  int x = clamp(px);
  int y = clamp(py);
  bitSet(field[y], x);
}

void clearPoint(byte* field, int px, int py) {
  int x = clamp(px);
  int y = clamp(py);
  bitClear(field[y], x);
}

int numberOfNeighbours(byte* field, int x, int y) {
    int result = 0;
    for (int i = x - 1; i <= x + 1; i++) {
        for (int j = y - 1; j <= y + 1; j++) {
            result += getPoint(field, i, j);
        }
    }
    return result - getPoint(field, x, y);
}

int stuckGenerations = 0;
int population = 0;

const int MAX_STUCK = 5;

void gameOfLife() {
  if (stuckGenerations > MAX_STUCK) {
    stuckGenerations = 0;
    randomizeField();
    return;
  }
  byte nextField[8];
  memset(nextField, 0, 8);
  int numberOfLiving = 0;
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      int neighbours = numberOfNeighbours(field, x, y);
      if (getPoint(field, x, y) == 1) {
        if (neighbours == 2 || neighbours == 3) {
          setPoint(nextField, x, y);
          numberOfLiving++;
        } else {
          clearPoint(nextField, x, y);
        }
      } else {
        if (neighbours == 3) {
          setPoint(nextField, x, y);
          numberOfLiving++;
        }
      }
    }
  }
  if (numberOfLiving == population) {
    stuckGenerations++;
  } else {
    stuckGenerations = 0;
  }
  population = numberOfLiving;
  for (int i = 0; i < 8; i++) {
    field[i] = nextField[i];
  }
}

// ----------- end of game of life -----------------

void randomizeField() {
  for (int i = 0; i < 8; i++) 
  {  
     field[i] = random(256);
  }  
}


long startTime;


void setup() {
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  pinMode(rdata, OUTPUT);
  pinMode(rclock, OUTPUT);
  pinMode(rlatch, OUTPUT);
  
  Serial.begin(9600);
  digitalWrite(13, HIGH);
  
  randomizeField();
  startTime = millis();
}

const int GAME_OF_LIFE = 0;
const int SMILE_HAPPY = 1;
const int SMILE_SAD = 2;
const int SMILE_INDIFFERENT = 3;

int color = 1;
int mode = GAME_OF_LIFE;

void loop() {
  if (Serial.available() > 0) 
  {
    int command = Serial.read();
    if (command == 0x30) {
      color = 0;
      mode = GAME_OF_LIFE;
    } else if (command == 0x31) {
      color = 1;
      mode = GAME_OF_LIFE;
    } else if (command == 0x32) {
      color = 1;
      mode = SMILE_HAPPY;
    } else if (command == 0x33) {
      color = 0;
      mode = SMILE_SAD;
    } else {
      color = 0;
      mode = SMILE_INDIFFERENT;
    }
  }
  
  if (millis() - startTime > 250) 
  {
    if (mode == GAME_OF_LIFE) {
      gameOfLife();
      startTime = millis();
    } else if (mode == SMILE_HAPPY) {
      happyFace();
    } else if (mode == SMILE_SAD) {
      sadFace();
    } else if (mode == SMILE_INDIFFERENT) {
      indifferentFace();
    }
  }
  
  drawField(color);
}
