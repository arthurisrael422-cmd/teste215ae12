// Ponte automatizada PC <-> ESP32 <-> FPGA.
// O PC envia "C" pela USB. O ESP32 pulsa GPIO27, aguarda o toggle da
// FPGA mudar e responde "R,<digito>".

const int PIN_BIT0    = 18;
const int PIN_BIT1    = 19;
const int PIN_BIT2    = 21;
const int PIN_BIT3    = 22;
const int PIN_TOGGLE  = 23;
const int PIN_TRIGGER = 27;

const unsigned long RESULT_TIMEOUT_MS = 5000;

uint8_t lerPrevisao() {
  return (digitalRead(PIN_BIT3) << 3)
       | (digitalRead(PIN_BIT2) << 2)
       | (digitalRead(PIN_BIT1) << 1)
       |  digitalRead(PIN_BIT0);
}

void classificar() {
  const int toggleInicial = digitalRead(PIN_TOGGLE);

  // Pulso longo para o sincronizador da FPGA detectar com folga.
  digitalWrite(PIN_TRIGGER, HIGH);
  delay(10);
  digitalWrite(PIN_TRIGGER, LOW);

  const unsigned long inicio = millis();
  while (digitalRead(PIN_TOGGLE) == toggleInicial) {
    if (millis() - inicio >= RESULT_TIMEOUT_MS) {
      Serial.println("E,TIMEOUT");
      return;
    }
    delay(1);
  }

  // Os quatro bits ja sao registrados pela FPGA antes da troca do toggle.
  delayMicroseconds(100);
  const uint8_t previsao = lerPrevisao();

  if (previsao <= 9) {
    Serial.print("R,");
    Serial.println(previsao);
  } else {
    Serial.print("E,DIGITO_INVALIDO,");
    Serial.println(previsao);
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(PIN_BIT0, INPUT_PULLDOWN);
  pinMode(PIN_BIT1, INPUT_PULLDOWN);
  pinMode(PIN_BIT2, INPUT_PULLDOWN);
  pinMode(PIN_BIT3, INPUT_PULLDOWN);
  pinMode(PIN_TOGGLE, INPUT_PULLDOWN);

  pinMode(PIN_TRIGGER, OUTPUT);
  digitalWrite(PIN_TRIGGER, LOW);

  delay(500);
  Serial.println("READY");
}

void loop() {
  if (!Serial.available()) {
    return;
  }

  const char comando = Serial.read();

  // Descarta CR/LF e aceita apenas um comando de classificacao por vez.
  if (comando == 'C' || comando == 'c') {
    while (Serial.available()) {
      Serial.read();
    }
    classificar();
  }
}
