clc; clear; close all;

gs_lat = 37.5;
gs_lon = 126.9;
gs_alt = 100;

startTime = datetime(2024,8,13,0,0,0,0);
stopTime = startTime + days(5);
sampleTime = 10; %seconds
sc = satelliteScenario(startTime, stopTime, sampleTime);

tleFile = "miman.tle";
miman = satellite(sc, tleFile, "Name", "Miman", "OrbitPropagator","sgp4");

gs = groundStation(sc, gs_lat, gs_lon, "Name", "Yonsei", "Altitude", gs_alt);
ac = access(miman,gs);
intvls = accessIntervals(ac);
play(sc)


minutes = 0:(5 * 24 * 60 * 6); % 5일 동안 10초 단위
time = startTime + seconds(minutes * 10);  % 10초 단위의 시간 벡터

[az, elev, radius] = deal(zeros(length(time), 1));

for idx = 1:length(time)
    [az(idx), elev(idx), radius(idx)] = aer(gs, miman, time(idx)); % 위성 Elevation 계산
end


above_horizon = elev >= 0;   % Elevation이 0도 이상인지 확인 (True/False 벡터)
pass_changes = diff([0; above_horizon; 0]);  % 변화 감지 (1: AOS, -1: LOS)

aos_indices = find(pass_changes == 1); % 신호 수신 시작 (AOS)
los_indices = find(pass_changes == -1) - 1; % 신호 수신 종료 (LOS)

aos_times = time(aos_indices);
los_times = time(los_indices);
max_elevations = arrayfun(@(s, e) max(elev(s:e)), aos_indices, los_indices);

aos_times_kst = aos_times + hours(9);
los_times_kst = los_times + hours(9);

fprintf('\n위성 패스 목록 (KST 기준)\n');
fprintf('-----------------------------------------------------------------------------\n');
fprintf('Pass Number |       AOS (KST)       |       LOS (KST)       | Max Elev (deg)\n');
fprintf('-----------------------------------------------------------------------------\n');

for k = 1:length(aos_times)
    fprintf(' %6d     |  %s  |  %s  |   %.2f°\n', ...
            k, datestr(aos_times_kst(k), 'yyyy-mm-dd HH:MM:SS'), ...
            datestr(los_times_kst(k), 'yyyy-mm-dd HH:MM:SS'), ...
            max_elevations(k));
end
fprintf('-----------------------------------------------------------------------------\n');
