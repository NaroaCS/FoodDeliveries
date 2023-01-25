#include <SPI.h>

#include <Ethernet.h>

#include <EthernetUdp.h>


#define PIN_SLIDE_A A1
#define PIN_SLIDE_B A2
#define PIN_SLIDE_C A3
#define PIN_SLIDE_D A4

void setup() {

  pinMode(PIN_SLIDE_A, INPUT);
  pinMode(PIN_SLIDE_B, INPUT);
  pinMode(PIN_SLIDE_C, INPUT);
  pinMode(PIN_SLIDE_D, INPUT);
  Serial.begin(9600);
}

void loop() {

    Serial.print("A1: ");
    Serial.print(analogRead(PIN_SLIDE_A));
    Serial.println(" ");
    delay(200);
    Serial.print("A2: ");
    Serial.print(analogRead(PIN_SLIDE_B));
    Serial.println("  ");
    delay(200);
    Serial.print("A3: ");
    Serial.print(analogRead(PIN_SLIDE_C));
    Serial.println("  ");
    delay(200);
    Serial.print("A4: ");
    Serial.print(analogRead(PIN_SLIDE_D));
    Serial.println("  ");
    delay(200);
}
