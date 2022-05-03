clear; close all; clc;
%A = readmatrix('test3_dziala.txt'); % 25 kwietnia 2021
%A = readmatrix('dane_test4.txt');   % 25 kwietnia 2021
%A = readmatrix('test5.txt');        % 21 czerwca 2021
%A = readmatrix('test6.txt');        % 21 czerwca 2021
%A = readmatrix('21grudnia_15stopni.txt');    %2022    
%A = readmatrix('21grudnia_25stopni.txt');        
%A = readmatrix('21grudnia_35stopni.txt');        
%A = readmatrix('21czerwca_15stopni.txt');        
%A = readmatrix('21czerwca_25stopni.txt');        
%A = readmatrix('21czerwca_35stopni.txt');      
A = readmatrix('21grudnia_35stopni.txt'); 

% WPISZ DATĘ BADANIA!!!!!!!!!!!!!!!!!!!!!!!!!!!
rok = 2022;
miesiac = 12;
dzien = 21;

% Czas trwania badania w minutach
czas = (1 : length(A));

% Zmiana kąta elewacji panelu stałego
A(:,7) = max(A(:,7));

% Kąt nachylenia deski
Y = 90 - A(:,7);

% Obliczenie kąta elewacji trackera jeszcze raz
A(:,6) = 90 - rad2deg(acos(cos(deg2rad(A(:,5))).*cos(deg2rad(Y))));

% Obliczenie kąta azymutu trackera jeszcze raz 
A(:,5) = rad2deg(asin(sin(deg2rad(A(:,5)))./sin(deg2rad(90-A(:,6)))));

% Napięcie na panelu z trackerem
%plot(czas', A(:,3));

% Napięcie na panelu stałym
%plot(czas', A(:,4));


% % Kąt azymutu trackera
% plot(czas', A(:,5)); axis([1 1440 -200 200]);
% grid on; figure
% 
% % Kąt elewacji trackera
% plot(czas', A(:,6));
% grid on; figure
% 
% % Kąt azymutu panelu stałego
% plot(czas', zeros(length(czas), 1));
% grid on; figure
% 
% % Kąt elewacji panelu stałego
% plot(czas', A(:,7));
% grid on; figure
% 
% % Kąt azymutu Słońca
% plot(czas', A(:,8));
% grid on; figure
% 
% % Kąt elewacji Słońca
%plot(minutes(czas'), A(:,9), 'DurationTickFormat','hh:mm:ss');
%grid on; xlim ylim

%% Czas na potrzeby osi X wykresów
dt = datetime(rok,miesiac,dzien,0,czas,0);

%% Elewacja trackera i Słońca na jednym wykresie
figure('Renderer', 'painters', 'Position', [0 570 500 400])
plot(dt, A(:,7), 'DateTimeTickFormat','HH:mm');
grid on; hold on
plot(dt, A(:,6), 'DateTimeTickFormat','HH:mm');
plot(dt, A(:,9), 'DateTimeTickFormat','HH:mm');
plot(dt, zeros(length(czas), 1), 'k--', 'DateTimeTickFormat','HH:mm');
xlim([datetime(rok,miesiac,dzien,0,0,0) datetime(rok,miesiac,dzien,0,1439,0)]);
legend('Kąt elewacji panelu stałego', 'Kąt elewacji trackera', 'Kąt elewacji Słońca', 'Horyzont');
xlabel('t [h]')
ylabel('\alpha [°]')
title('Kąt elewacji');

%% Azymut trackera i Słońca na jednym wykresie
figure('Renderer', 'painters', 'Position', [0 70 500 400])
plot(dt, zeros(length(czas), 1), 'DateTimeTickFormat','HH:mm');
grid on; hold on;
plot(dt, A(:,5), 'DateTimeTickFormat','HH:mm'); xlim([datetime(rok,miesiac,dzien,0,0,0) datetime(rok,miesiac,dzien,0,1439,0)]);
plot(dt, A(:,8), 'DateTimeTickFormat','HH:mm');
legend('Kąt azymutu panelu stałego', 'Kąt azymutu trackera', 'Kąt azymutu Słońca');
xlabel('t [h]')
ylabel('\beta [°]')
title('Kąt azymutu');

%% Wykres 3-wymiarowy
figure('Renderer', 'painters', 'Position', [1020 170 900 700])
plot3(cos(deg2rad(A(1,7))) .* cos(deg2rad(0)), cos(deg2rad(A(1,7))) .* sin(deg2rad(0)), sin(deg2rad(A(1,7))), '*', 'MarkerSize', 10);
hold on; grid on;
plot3(cos(deg2rad(A(:,6))) .* cos(deg2rad(A(:,5))), cos(deg2rad(A(:,6))) .* sin(deg2rad(A(:,5))), sin(deg2rad(A(:,6))));
plot3(cos(deg2rad(A(:,9))) .* cos(deg2rad(A(:,8))), cos(deg2rad(A(:,9))) .* sin(deg2rad(A(:,8))), sin(deg2rad(A(:,9))));

plot3(0, 0, 0, '.', 'MarkerSize', 50);
teta = -pi:0.01:pi;
x = cos(teta);
y = sin(teta);
fill(x, y, [0.2 0 0]);
legend('Kierunek panelu stałego', 'Kierunek trackera', 'Położenie Słońca na niebie', 'Położenie urządzenia', 'Ziemia');
axis square
title('Tor przemieszczania się kierunku paneli i Słońca na niebie');

%% Obliczanie kąta odchylenia dla panelu stałego **************************
% Oblicza kąt między kierunkiem do słońca normalną do powierzchni modułow 
AOI_staly = pvl_getaoi(Y(1), 180, 90-A(:,9), -(A(:,8)-180));

figure('Renderer', 'painters', 'Position', [500 570 500 400])
plot(dt,AOI_staly,'-', 'DateTimeTickFormat','HH:mm')
xlim([datetime(rok,miesiac,dzien,0,0,0) datetime(rok,miesiac,dzien,0,1439,0)]);
grid on; hold on;
xlabel('t [h]')
ylabel('\gamma [°]')

%% Obliczanie kąta odchylenia dla trackera jednosilnikowego **************************
% Oblicza kąt między kierunkiem do słońca normalną do powierzchni modułow 
AOI_1_osiowy = pvl_getaoi(90-A(:,6), -A(:,5)+180, 90-A(:,9), -(A(:,8)-180));

plot(dt,AOI_1_osiowy,'-', 'DateTimeTickFormat','HH:mm')


%% Obliczanie kąta odchylenia dla trackera dwusilnikowego **************************
% Oblicza kąt między kierunkiem do słońca normalną do powierzchni modułow 
AOI_2_osiowy = zeros(length(AOI_staly),1);

plot(dt,AOI_2_osiowy,'-', 'DateTimeTickFormat','HH:mm')
legend('Kąt odchylenia dla panelu stałego', 'Kąt odchylenia dla trackera jednosilnikowego', 'Kąt odchylenia dla trackera dwusilnikowego');
title('Kąt pomiędzy kierunkiem paneli, a kierunkiem na Słońce');


%% Wybór z bazy typu modułu (czytane są parametry)                                                   
% Define the PV module from the Sandia PV Module Database.  
ModuleParameters = pvl_sapmmoduledb(486,'SandiaModuleDatabase_20120925.xlsx');
%% Wybór z bazy falownika                                                                           
load('SandiaInverterDatabaseSAM2014.1.14.mat')
Inverter = SNLInverterDB(1059);
%
clear InverterNames SNLInverterDB
%% Konfiguracja modułow                                                                     
Array.Tilt = 90-A(1,7);      % Array tilt angle (deg)
Array.Azimuth = 180;  % Array azimuth (180 deg indicates array faces South)
Array.Ms = 1;        % Number of modules in series                                          
Array.Mp = 1;         % Number of paralell strings                                           
%% Dodatkowe paramety modułow 
%Module                     Type Mount            a         b
%Glass/cell/glass 	        Open rack            -3.47    -.0594  POLY MONO
%Glass/cell/glass           Close roof mount     -2.98    -.0471
%Glass/cell/polymer sheet   Open rack            -3.56    -.0750
%Glass/cell/polymer sheet   Insulated back       -2.81    -.0455
%Polymer/thin-film/steel    Open rack            -3.58    -.113   CIGS
%22X Linear Concentrator    Tracker              -3.23    -.130
% 
Array.a = -3.56;
Array.b = -0.075;
%% Definicja czasu symulacja (godzinowa rozdzilczość)   
miesiac_str = int2str(miesiac);
if length(miesiac_str) == 1
    miesiac_str = append('0', miesiac_str);
end
dzien_str = int2str(dzien);
if length(dzien_str) == 1
    dzien_str = append('0', dzien_str);
end
data_start_str = append(int2str(rok), '-', miesiac_str, '-', dzien_str, ' 00:00:00');
data_stop_str =  append(int2str(rok), '-', miesiac_str, '-', dzien_str, ' 23:59:00');
t1= datetime(data_start_str);
t2= datetime(data_stop_str);
TimeStr = t1:minutes(1):t2;
TimeMatlab=datenum(TimeStr');
SiteTimeZone=0; 
Time = pvl_maketimestruct(TimeMatlab, ones(size(TimeMatlab))*SiteTimeZone); 
%%  Definicja lokalizacji Akademik T-6 Wrocław                                            
SiteLatitude  = 51.11808;  % szerokść geogr
SiteLongitude = 17.04919;  % długość geogr
SiteElevation = 120;     % wysokość nad poziomem morza
Location = pvl_makelocationstruct(SiteLatitude,SiteLongitude,SiteElevation);
%%  obliczanie składowych nasłonecznienia (czyste niebo)                        
%   direct normal irradiance (DNI), 
%   diffuse horizontal irradiance (DHI), 
%   global horizontal irradiance (GHI) 
[GHI, DNI, DHI]= pvl_clearsky_ineichen(Time, Location);
%  Irradiancja wykres
% figure
% plot(Time.hour,DNI,'-*')
% hold all
% plot(Time.hour,DHI,'-o')
% plot(Time.hour,GHI,'-x')
% legend('DNI','DHI','GHI')
% xlabel('Hour of Day')
% ylabel('Irradiance (W/m^2)')
% title('Promieniowanie')
% grid on 
%% symulacja warunków pogodowych (tu są stałe)                                      
PresPa=   10e4*ones(length(TimeMatlab),1); % symulowane stałe ciśnienie
DryBulb = 5*  ones(length(TimeMatlab),1); % symulowana stała wilgotność
Wspd=     5*  ones(length(TimeMatlab),1); % symulowana stała prędkość wiatru
Temp=    20*  ones(length(TimeMatlab),1); % symulowana stała temperatura otocz.
%% Obliczenia pozycji słońca                                                      
% Jeżeli ciśnienie [Pa] i temperatura [st.C] otoczenia są znane mozna dać jako parametr
[SunAz, SunEl, AppSunEl, SolarTime] = pvl_ephemeris(Time,Location,PresPa,Temp);
%
% figure
% plot(Time.hour,90-AppSunEl,'-s')
% hold all
% plot(Time.hour,SunAz,'-o')
% plot(Time.hour,SunEl,'-x')
% legend('Kąt zenitu','Kąt azymutu' ,'Kąt elewacji słońca')
% xlabel('Godzina')
% ylabel('Kąt (st.)')
% title('Pozycja słońca')
% grid on 
%% Obliczenia masy powietrza                                                     
AMa = pvl_absoluteairmass(pvl_relativeairmass(90-AppSunEl),PresPa);
% figure
% plot(czas',AMa)
% xlabel('t[s]')
% ylabel('AMa')
% title('Masa powietrza')
% grid on 
%% Obliczanie kąta odchylenia ********************************************       
% Oblicza kąt między kierunkiem do słońca normalną do powierzchni modułow 



%% Obliczanie bezpośredniej składowej promieniowania                           
Eb_staly = 0*AOI_staly;  
Eb_staly(AOI_staly<90) = DNI(AOI_staly<90).*cosd(AOI_staly(AOI_staly<90));  % Tylko gdy słońce jest widoczne przez moduły
Eb_1_osiowy = 0*AOI_1_osiowy;  
Eb_1_osiowy(AOI_1_osiowy<90) = DNI(AOI_1_osiowy<90).*cosd(AOI_1_osiowy(AOI_1_osiowy<90));
Eb_2_osiowy = 0*AOI_2_osiowy;  
Eb_2_osiowy(AOI_2_osiowy<90) = DNI(AOI_2_osiowy<90).*cosd(AOI_2_osiowy(AOI_2_osiowy<90));
% figure
% plot(czas',Eb_staly)
% hold on
% plot(czas',GHI)
% hold off
% legend('Eb','GHI')
% xlabel('Godzina')
% ylabel('Irrad. (W/m2)')
% title('Beam component of the irradiance')
% grid on 

%% Obliczanie składnika promieniowania rozproszonego                         
% * <pvl_isotropicsky_help.html  |pvl_isotropicsky|>
% * <pvl_haydavies1980_help.html |pvl_haydavies1980|>
% * <pvl_kingdiffuse_help.html |pvl_kingdiffuse|>
% * <pvl_reindl1990_help.html |pvl_reindl1990|>
DHI(isnan(DHI))=0;
GHI(isnan(GHI))=0;
EdiffSky = pvl_isotropicsky(Array.Tilt,DHI); 

%% Obliczenie składnika promieniowania odbitego od podłoża                  
Albedo = 0.2;
EdiffGround = pvl_grounddiffuse(Array.Tilt,GHI, Albedo);

E_staly = Eb_staly + EdiffSky + EdiffGround;  % Total incident irradiance (W/m^2)
E_staly(isnan(E_staly))=0;
E_1_osiowy = Eb_1_osiowy + EdiffSky + EdiffGround;  % Total incident irradiance (W/m^2)
E_1_osiowy(isnan(E_1_osiowy))=0;
E_2_osiowy = Eb_2_osiowy + EdiffSky + EdiffGround;  % Total incident irradiance (W/m^2)
E_2_osiowy(isnan(E_2_osiowy))=0;

Ediff = EdiffSky + EdiffGround;   % Total diffuse incident irradiance (W/m^2)
%
% figure
% plot(Time.hour,E_staly,'-s')
% hold all
% plot(Time.hour,EdiffSky,'-o')
% plot(Time.hour,EdiffGround,'-x')
% legend('Eb','EdiffSky','EdiffGround')
% xlabel('Godzina')
% ylabel('Irradiance (W/m^2')
% title('Irradiance')
% grid on 
%% Uwzględnienie zabrudzenia*                                               
SF=0.98;

%% Obliczanie temperatury modułow                                              
E0 = 1000; % Reference irradiance (1000 W/m^2)
celltemp_staly = pvl_sapmcelltemp(E_staly, E0, Array.a, Array.b, Wspd, DryBulb, ModuleParameters.delT);
celltemp_1_osiowy = pvl_sapmcelltemp(E_1_osiowy, E0, Array.a, Array.b, Wspd, DryBulb, ModuleParameters.delT);
celltemp_2_osiowy = pvl_sapmcelltemp(E_2_osiowy, E0, Array.a, Array.b, Wspd, DryBulb, ModuleParameters.delT);


%% Uwzględnienie charakterystyki modułów                                    
% obliczenie generowanego prądu, napięcia i mocy DC
F1 = max(0,polyval(ModuleParameters.a,AMa));          % Spectral loss function 

F2_staly = max(0,polyval(ModuleParameters.b,AOI_staly));          % Angle of incidence loss function
F2_1_osiowy = max(0,polyval(ModuleParameters.b,AOI_1_osiowy));          % Angle of incidence loss function
F2_2_osiowy = max(0,polyval(ModuleParameters.b,AOI_2_osiowy));          % Angle of incidence loss function

Ee_staly = F1.*((Eb_staly.*F2_staly+ModuleParameters.fd.*Ediff)/E0)*SF; % Effective irradiance
Ee_1_osiowy = F1.*((Eb_1_osiowy.*F2_1_osiowy+ModuleParameters.fd.*Ediff)/E0)*SF; % Effective irradiance
Ee_2_osiowy = F1.*((Eb_2_osiowy.*F2_2_osiowy+ModuleParameters.fd.*Ediff)/E0)*SF; % Effective irradiance

Ee_staly(isnan(Ee_staly))=0;  % Set any NaNs to zero
Ee_1_osiowy(isnan(Ee_1_osiowy))=0;
Ee_2_osiowy(isnan(Ee_2_osiowy))=0;

mSAPMResults_staly = pvl_sapm(ModuleParameters, Ee_staly, celltemp_staly); 
mSAPMResults_1_osiowy = pvl_sapm(ModuleParameters, Ee_1_osiowy, celltemp_1_osiowy); 
mSAPMResults_2_osiowy = pvl_sapm(ModuleParameters, Ee_2_osiowy, celltemp_2_osiowy); 

%*************
aSAPMResults_staly.Vmp = Array.Ms  *mSAPMResults_staly.Vmp;
aSAPMResults_staly.Imp = Array.Mp  *mSAPMResults_staly.Imp;
aSAPMResults_staly.Pmp = aSAPMResults_staly.Vmp .* aSAPMResults_staly.Imp;

aSAPMResults_1_osiowy.Vmp = Array.Ms  *mSAPMResults_1_osiowy.Vmp;
aSAPMResults_1_osiowy.Imp = Array.Mp  *mSAPMResults_1_osiowy.Imp;
aSAPMResults_1_osiowy.Pmp = aSAPMResults_1_osiowy.Vmp .* aSAPMResults_1_osiowy.Imp;

aSAPMResults_2_osiowy.Vmp = Array.Ms  *mSAPMResults_2_osiowy.Vmp;
aSAPMResults_2_osiowy.Imp = Array.Mp  *mSAPMResults_2_osiowy.Imp;
aSAPMResults_2_osiowy.Pmp = aSAPMResults_2_osiowy.Vmp .* aSAPMResults_2_osiowy.Imp;
%*************
figure('Renderer', 'painters', 'Position', [500 70 500 400])
plot(dt,aSAPMResults_staly.Pmp, 'DateTimeTickFormat','HH:mm'); hold on; grid on;
plot(dt,aSAPMResults_1_osiowy.Pmp, 'DateTimeTickFormat','HH:mm');
plot(dt,aSAPMResults_2_osiowy.Pmp, 'DateTimeTickFormat','HH:mm');
xlim([datetime(rok,miesiac,dzien,0,0,0) datetime(rok,miesiac,dzien,0,1439,0)]);
legend('Panel stały', 'Tracker 1-osiowy', 'Tracker 2-osiowy')
xlabel('t [h]')
ylabel('P [W]')
title('Moc na panelach PV')

%% Porównanie energii wygenerowanej przez wszystkie konfiguracje
% Energia wyprodukowana przez panele [kWh]
E_staly = trapz(aSAPMResults_staly.Pmp) / 60 / 1000;
E_1_osiowy = trapz(aSAPMResults_1_osiowy.Pmp) / 60 / 1000;
E_2_osiowy = trapz(aSAPMResults_2_osiowy.Pmp) / 60 / 1000;

% Zysk energii w stosunku do panelu stałego [%]
zysk_1_osiowy = E_1_osiowy / E_staly * 100 - 100;  
zysk_2_osiowy = E_2_osiowy / E_staly * 100 - 100;    

% Stosunek energii produkowanej przez tracker 1-osiowy do en. produkowanej
% przez tracker 2-os. [%]
E_1os_do_2os = E_1_osiowy / E_2_osiowy * 100; 

disp(['Energia wyprodukowana przez panel stały: ',num2str(E_staly,4),'kWh']);
disp(['Energia wyprodukowana przez tracker 1-osiowy: ',num2str(E_1_osiowy,4),'kWh']);
disp(['Energia wyprodukowana przez tracker 2-osiowy: ',num2str(E_2_osiowy,4),'kWh']);

disp(['Zysk energii trackera 1-osiowego w stosunku do panelu stałego: ',num2str(zysk_1_osiowy,3),'%']);
disp(['Zysk energii trackera 2-osiowego w stosunku do panelu stałego: ',num2str(zysk_2_osiowy,3),'%']);

disp(['Stosunek energii z trackera 1-os. do energii z trackera 2-os.: ',num2str(E_1os_do_2os,3),'%']);


