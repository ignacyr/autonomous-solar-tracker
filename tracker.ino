#include <SolarPosition.h>
#include <DS3231.h>
#include <SD.h>
#include <SPI.h>
#include <Wire.h>


DS3231  rtc(SDA, SCL); // init DS3231

// Wybór trybu
int tryb; 
// enum tryb {wylaczony = 0, reczny = 1, automatyczny = 2, testowy = 3}; 

// Napięcie na panelach fotowoltaicznych
float napiecie1 = 0.0;
float napiecie2 = 0.0;

// Wartość na przetwornikach A/C
int wejscieA0 = 0;
int wejscieA1 = 0;

// Aktualny azymut Słońca
float aktualny_azymut_slonca = 0.0;
float aktualna_elewacja_slonca = 0.0;

// Wartość zadana 
int odczyt_z_potencjometru = 0;
float wartosc_zadana_kata = 0.0;

// Zmienne przechowujące datę i czas
String data;
String czas;

File file; // Obiekt plik

int pinCS = 10; // Do microSD

const float szerokosc_geograficzna = 51.11808;
const float dlugosc_geograficzna   = 17.04919;
SolarPosition Akademik(szerokosc_geograficzna, dlugosc_geograficzna);

// Zmienna określająca czy jest noc czy dzień
bool dzien = true; 

// Pomocnicza zmienna do częstotliwości zapisu danych
int licznik = 0; 

// Zmienne do obliczania kąta przez moduł żyroskopu z akcelerometrem
const int MPU_addr=0x69;
int16_t AcX,AcY,AcZ,Tmp,GyX,GyY,GyZ;
int minVal=265;
int maxVal=402;
double x;
double y;

// Czas w trybie testowym
tmElements_t czas_test_strukt = {0, 0, 0, 0, 21, 9, CalendarYrToTm(2022)};
time_t czas_test = makeTime(czas_test_strukt); // Czas przykładowego dnia na potrzeby testu
const unsigned int czas_poczatkowy = czas_test;

// Kąt startowy
const int kat_startowy = 90;

// Deklaracje funkcji
void MPU_init();
void silnikNaZachod_krok();
void silnikNaWschod_krok();
time_t przelicz_czas();
float kat_elewacji();
void ustaw_tracker_na_wschod();
void noc_czy_dzien();

void setup() {
  tryb = 0;
  digitalWrite(8, LOW);   // czerwona - tryb testowy
  digitalWrite(3, LOW);   // niebieska - tryb ręczny
  digitalWrite(9, LOW);   // zielona - tryb automatyczny
   
  Serial.begin(9600); // Komunikacja przez port szeregowy

  // Wyjścia dla lampki trybu
  pinMode(8, OUTPUT); // czerwona - wyłączony
  pinMode(3, OUTPUT); // niebieska - ręczny
  pinMode(9, OUTPUT); // zielona - automatyczny

  // Wejście dla przycisku sterowania trybem
  pinMode(2, INPUT_PULLUP);

  // Wyjścia do sterowania silnikiem
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(7, OUTPUT);

  // Wejścia do pomiaru napięcia
  pinMode(A0, INPUT);
  pinMode(A1, INPUT);

  // Wejście do potencjometru
  pinMode(A2, INPUT);
    
  // Inicjalizacja RTC  
  rtc.begin(); 
  //rtc.setTime(12,34,00);
  //rtc.setDate(04,12,2021);
  //rtc.setDOW(6);

  // Wszystko do microSD
  pinMode(pinCS, OUTPUT);
  
  // Inicjalizacja modułu microSD
  /*if(SD.begin())
  {
    Serial.println("Karta SD jest gotowa do uzycia");
  }
  else
  {
    Serial.println("Inicjalizacja modulu karty SD nieudana");
    return;
  }  */
  SD.begin();

  MPU_init();

  SolarPosition::setTimeProvider(przelicz_czas);
}

void loop() { 
  
  noc_czy_dzien();
  
  // Zmiana trybów
  if (!(digitalRead(2)) && tryb == 0){
    tryb = 1;
    digitalWrite(8, LOW);
    digitalWrite(3, HIGH);
    digitalWrite(9, LOW);
  }
  else if (!(digitalRead(2)) && tryb == 1){
    tryb = 2;
    digitalWrite(8, LOW);
    digitalWrite(3, LOW);
    digitalWrite(9, HIGH);
  }
  else if (!(digitalRead(2)) && tryb == 2){
    tryb = 3;
    digitalWrite(8, HIGH);
    digitalWrite(3, LOW);
    digitalWrite(9, LOW);
    //SolarPosition::setTimeProvider(czas_test);
    ustaw_tracker_na_wschod();
  }
  else if (!(digitalRead(2)) && tryb == 3){
    tryb = 0;
    digitalWrite(8, LOW);
    digitalWrite(3, LOW);
    digitalWrite(9, LOW);
    czas_test_strukt = {0, 0, 0, 0, 21, 9, CalendarYrToTm(2022)};
    czas_test = makeTime(czas_test_strukt);
  }
    
  // Pobranie czasu z modułu zegara czasu rzeczywistego lub czas testowy
  if (tryb == 3){
    String dayy;
    String monthh;
    String yearr;
    String hourr;
    String minutee;
    String secondd;
    
    if (String(day(czas_test)).length() == 2){
      dayy = String(day(czas_test));
    }
    else{
      dayy = "0" + String(day(czas_test));
    }
    
    if (String(month(czas_test)).length() == 2){
      monthh = String(month(czas_test));
    }
    else{
      monthh = "0" + String(month(czas_test));
    }

    yearr = String(year(czas_test));
    
    if (String(hour(czas_test)).length() == 2){
      hourr = String(hour(czas_test));
    }
    else{
      hourr = "0" + String(hour(czas_test));
    }

    if (String(minute(czas_test)).length() == 2){
      minutee = String(minute(czas_test));
    }
    else{
      minutee = "0" + String(minute(czas_test));
    }

    if (String(second(czas_test)).length() == 2){
      secondd = String(second(czas_test));
    }
    else{
      secondd = "0" + String(second(czas_test));
    }
    
    data = dayy + "." + monthh + "." + yearr;
    czas = hourr + ":" + minutee + ":" + secondd;
  }
  else{
    data = rtc.getDateStr();
    czas = rtc.getTimeStr();
  }
  

  // Pomiar kąta nachylenia
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr,14,true);
  AcX = Wire.read()<<8|Wire.read();
  AcY = Wire.read()<<8|Wire.read();
  AcZ = Wire.read()<<8|Wire.read();
  int xAng = map(AcX,minVal,maxVal,-90,90);
  int yAng = map(AcY,minVal,maxVal,-90,90);
  int zAng = map(AcZ,minVal,maxVal,-90,90);

  // Obliczenie kątów nachylenia w osi 'x' i 'y'
  x = RAD_TO_DEG * (atan2(-yAng, -zAng)+PI);
  if (x >= 180 && x <= 360)
    x = x - 360;  
  y = RAD_TO_DEG * (atan2(-xAng, -zAng)+PI);
  if (y >= 180 && y <= 360)
    y = y - 360;
    
  // Aktualny azymut i elewacja Słońca w stosunku do południa
  if (tryb == 3){
    aktualny_azymut_slonca = 180-Akademik.getSolarPosition(czas_test).azimuth;
    aktualna_elewacja_slonca = Akademik.getSolarPosition(czas_test).elevation;
  }
  else{
    aktualny_azymut_slonca = 180-Akademik.getSolarPosition().azimuth;
    aktualna_elewacja_slonca = Akademik.getSolarPosition().elevation;
  }
   

  // od 0 do 1023 teoretycznie, w praktyce nigdy nie dochodi do 0 ani do 1023
  odczyt_z_potencjometru = analogRead(A2); 
  wartosc_zadana_kata = odczyt_z_potencjometru/1024.0*150-75;

  // Tryb ręczny
  if (tryb == 1){     
    if (wartosc_zadana_kata-1 > x){
      silnikNaWschod_krok();
    }
    else if (wartosc_zadana_kata+1 < x){
      silnikNaZachod_krok();
    }
  }
  // Tryb automatyczny
  else if (tryb == 2){
    if (dzien == true){
      if (aktualny_azymut_slonca-1 > x && x < kat_startowy){
        silnikNaWschod_krok();
      }
      else if (aktualny_azymut_slonca+1 < x && x > -kat_startowy){
        silnikNaZachod_krok();
      }   
    }
    else if (dzien == false){
      if (-4 > x){
        silnikNaWschod_krok();
      }
      else if (4 < x){
        silnikNaZachod_krok();
      }  
    }
  }
  // Tryb testowy
  else if (tryb == 3){
    if (dzien == true){
      if (aktualny_azymut_slonca-1 > x && x < kat_startowy){
        silnikNaWschod_krok();
      }
      else if (aktualny_azymut_slonca+1 < x && x > -kat_startowy){
        silnikNaZachod_krok();
      }   
    }
    //else if (dzien == false){
      //if (-4 > x){
       // silnikNaWschod_krok();
      //}
      //else if (4 < x){
       // silnikNaZachod_krok();
        //}  
      //}

    czas_test += 60; // Dodaj 600 sekund, czyli 10 minut, aby zrobić kolejny pomiar
    if (day(czas_test) > 21){
      czas_test_strukt = {0, 0, 0, 0, 21, 9, CalendarYrToTm(2022)};
      czas_test = makeTime(czas_test_strukt);
      tryb = 0;
      digitalWrite(8, LOW);
      digitalWrite(3, LOW);
      digitalWrite(9, LOW);
    }
  }

  pomiar_napiecia();

  zapis_na_karte_SD();

  port_szeregowy();

  delay(1000);
}

void port_szeregowy(){
  Serial.println("******************************");
  
  switch (tryb){
    case 0:
        Serial.println("Tracker wyłączony");
        break;
    case 1:
        Serial.println("Tryb ręczny");
        break;
    case 2:
        Serial.println("Tryb automatyczny");
        break;
    case 3: 
        Serial.println("Tryb testowy");
        break;
  }

  // Data i godzina na port szeregowy
  //Serial.print(rtc.getDOWStr());
  //Serial.print(" ");
  Serial.print(data);
  Serial.print(" -- ");
  Serial.println(czas);

  // Napięcie na port szeregowy
  Serial.print("Napięcie na panelu 1: ");
  Serial.print(napiecie1);
  Serial.println(" V");
  Serial.print("Napięcie na panelu 2: ");
  Serial.print(napiecie2);
  Serial.println(" V");

  // Wartość zadana kąta nachylenia w osi X
  Serial.print("Wartość zadana kąta rotacji trackera: ");
  Serial.println(wartosc_zadana_kata);

  // Kąt nachylenia na port szeregowy
  //Serial.print("Kat nachylenia w osi X = ");
  //Serial.println(x);
  //Serial.print("Kat nachylenia w osi Y = ");
  //Serial.println(y);
  
  // Aktualny azymut Słońca i trackera w stosunku do południa
  Serial.print("Kąt azymutu Słońca:   ");
  Serial.println(aktualny_azymut_slonca, 2);
  Serial.print("Kąt azymutu trackera: ");
  Serial.println(x);
  
  // Aktualna elewacja Słońca i trackera
  Serial.print("Kąt elewacji Słońca:   ");
  Serial.println(aktualna_elewacja_slonca, 2);
  Serial.print("Kąt elewacji trackera: ");
  Serial.println(kat_elewacji(x,y));

  Serial.print("Kąt elewacji panelu stałego: ");
  Serial.println(90 - abs(y)); // elewacja panelu stałego
}

void zapis_na_karte_SD(){  
  // Panel 1
  file = SD.open("dane.txt", FILE_WRITE);
  file.print(data);                        // 1. Data
  file.print(" ");    
  file.print(czas);                        // 2. Czas  
  file.print(" ");     
  file.print(napiecie1);                   // 3. Napięcie panelu z trackerem
  file.print(" ");
  file.print(napiecie2);                   // 4. Napięcie panelu stałego
  file.print(" ");       
  file.print(x);                           // 5. Kąt azymutu trackera  
  file.print(" ");     
  file.print(kat_elewacji(x,y));           // 6. Kąt elewacji trackera
  file.print(" ");
  file.print(90 - abs(y));                 // 7. Kąt elewacji panelu stałego 
  file.print(" ");
  file.print(aktualny_azymut_slonca, 2);   // 8. Kąt azymutu Słońca
  file.print(" ");
  file.print(aktualna_elewacja_slonca, 2); // 9. Kąt elewacji Słońca
  file.print(" ");
  file.println(tryb);                      // 10. Tryb
  file.close();
  
  /* // Panel 2
  file = SD.open("panel_2.txt", FILE_WRITE);
  file.print(data);
  file.print(" ");
  file.print(czas);
  file.print(" ");
  file.print(napiecie2);
  file.print(" ");
  file.println(90 - abs(y)); // elewacja panelu stałego 
  file.close();

  // Pozycja Słońca
  file = SD.open("pozycja_slonca.txt", FILE_WRITE);
  file.print(data);
  file.print(" ");
  file.print(czas);
  file.print(" ");
  file.print(aktualny_azymut_slonca, 2);  // azymut słońca
  file.print(" ");
  file.println(Akademik.getSolarPosition().elevation, 2);  // elewacja słońca
  file.close();*/
}

void pomiar_napiecia(){
  wejscieA0 = analogRead(A0);
  wejscieA1 = analogRead(A1);
  napiecie1 = (wejscieA0 * 10.0)/1024.0;
  napiecie2 = (wejscieA1 * 10.0)/1024.0;
}

void silnikNaZachod_krok(){
  digitalWrite(4, LOW);
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);
  digitalWrite(7, HIGH);
  delay(20);

  digitalWrite(4, LOW);
  digitalWrite(5, LOW);
  digitalWrite(6, HIGH);
  digitalWrite(7, LOW);
  delay(20);

  digitalWrite(4, LOW);
  digitalWrite(5, HIGH);
  digitalWrite(6, LOW);
  digitalWrite(7, LOW);
  delay(20);

  digitalWrite(4, HIGH);
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);
  digitalWrite(7, LOW);
  delay(20);
  
  digitalWrite(4, LOW);
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);
  digitalWrite(7, LOW);
  delay(20);
}

void silnikNaWschod_krok(){
  digitalWrite(4, HIGH);
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);
  digitalWrite(7, LOW);
  delay(20);

  digitalWrite(4, LOW);
  digitalWrite(5, HIGH);
  digitalWrite(6, LOW);
  digitalWrite(7, LOW);
  delay(20);

  digitalWrite(4, LOW);
  digitalWrite(5, LOW);
  digitalWrite(6, HIGH);
  digitalWrite(7, LOW);
  delay(20);

  digitalWrite(4, LOW);
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);
  digitalWrite(7, HIGH);
  delay(20);
  
  digitalWrite(4, LOW);
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);
  digitalWrite(7, LOW);
  delay(20);
}

void MPU_init(){
  // Inicjalizacja MPU
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);
}

time_t przelicz_czas(){
  String data = rtc.getDateStr();
  String czas = rtc.getTimeStr();
  
  int dzienMiesiaca = 10*int(data[0] - '0') + int(data[1] - '0');
  int miesiac       = 10*int(data[3] - '0') + int(data[4] - '0');
  int rok = 1000*int(data[6] - '0') + 100*int(data[7] - '0') + 10*int(data[8] - '0') + int(data[9] - '0');
  
  int godzina = 10*(czas[0] - '0') + (czas[1] - '0'); // Godzina w tym momencie
  int minuta  = 10*(czas[3] - '0') + (czas[4] - '0'); // Minuta w tym momencie
  int sekunda = 10*(czas[6] - '0') + (czas[7] - '0'); // Sekunda w tym momencie

  tmElements_t czas_strukt = {sekunda, minuta, godzina, 0, dzienMiesiaca, miesiac, CalendarYrToTm(rok)};
  time_t przeliczony_czas = makeTime(czas_strukt);
  return przeliczony_czas;
}

void noc_czy_dzien(){
  if (aktualna_elewacja_slonca > 0 && dzien == false){
    dzien = true;
  }
  else if (aktualna_elewacja_slonca < 0 && dzien == true){
    dzien = false;
  }
}

float kat_elewacji(float alfa, float beta){
  float alfa_rad = DEG_TO_RAD * alfa;
  float beta_rad = DEG_TO_RAD * beta;
  float elewacja = acos(cos(alfa_rad) * cos(beta_rad));
  return 90 - RAD_TO_DEG * elewacja;
}

void ustaw_tracker_na_wschod(){
  int potrzebne_kroki = (kat_startowy - x)/(kat_startowy*2) * 256;
  for (int i = 0; i < potrzebne_kroki; i++){
    digitalWrite(4, HIGH);
    digitalWrite(5, LOW);
    digitalWrite(6, LOW);
    digitalWrite(7, LOW);
    delay(20);
  
    digitalWrite(4, LOW);
    digitalWrite(5, HIGH);
    digitalWrite(6, LOW);
    digitalWrite(7, LOW);
    delay(20);
  
    digitalWrite(4, LOW);
    digitalWrite(5, LOW);
    digitalWrite(6, HIGH);
    digitalWrite(7, LOW);
    delay(20);
  
    digitalWrite(4, LOW);
    digitalWrite(5, LOW);
    digitalWrite(6, LOW);
    digitalWrite(7, HIGH);
    delay(20);
    
    digitalWrite(4, LOW);
    digitalWrite(5, LOW);
    digitalWrite(6, LOW);
    digitalWrite(7, LOW);
    delay(20);
  }
}
