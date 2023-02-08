#include <SPI.h>

#include <Ethernet.h>

#include <EthernetUdp.h>

#define PIN_SLIDE_A A0
#define PIN_SLIDE_B A1
#define BUTTON_A 2
#define BUTTON_B 3
#define BUTTON_C 4
#define BUTTON_D 5
boolean buttonState_A;
boolean buttonState_B;
boolean buttonState_C;
boolean buttonState_D;
int A, B, C, D;
int AA, BB, CC, DD;
#define DOWN 0

void setup() {

  pinMode(PIN_SLIDE_A, INPUT);
  pinMode(PIN_SLIDE_B, INPUT);
  pinMode(BUTTON_A, INPUT_PULLUP);
  AA = digitalRead(BUTTON_A);
  pinMode(BUTTON_B, INPUT_PULLUP);
  BB = digitalRead(BUTTON_B);
  pinMode(BUTTON_C, INPUT_PULLUP);
  CC = digitalRead(BUTTON_C);
  pinMode(BUTTON_D, INPUT_PULLUP);
  DD = digitalRead(BUTTON_D);
  Serial.begin(9600);
}

void loop() {
    
    Serial.print("A0: ");
    Serial.print(analogRead(PIN_SLIDE_A));
    Serial.println(" ");
    delay(200);

    Serial.print("A1: ");
    Serial.print(analogRead(PIN_SLIDE_B));
    Serial.println("  ");
    delay(200);

    A = AA;
    AA = digitalRead(BUTTON_A);
    if (A == DOWN && AA != DOWN){
      buttonState_A = !buttonState_A;
    }
    Serial.print("D2: ");
    Serial.println(buttonState_A);
    delay(200);

    B = BB;
    BB = digitalRead(BUTTON_B);
    if (B == DOWN && BB != DOWN){
      buttonState_B = !buttonState_B;
    }
    Serial.print("D3: ");
    Serial.println(buttonState_B);
    delay(200);

    C = CC;
    CC = digitalRead(BUTTON_C);
    if (C == DOWN && CC != DOWN){
      buttonState_C = !buttonState_C;
    }
    Serial.print("D4: ");
    Serial.println(buttonState_C);
    delay(200);

    D = DD;
    DD = digitalRead(BUTTON_D);
    if (D == DOWN && DD != DOWN){
      buttonState_D = !buttonState_D;
    }
    Serial.print("D5: ");
    Serial.println(buttonState_D);
    delay(200);


}
