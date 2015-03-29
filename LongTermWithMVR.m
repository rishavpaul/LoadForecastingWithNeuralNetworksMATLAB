%% ARRANGING THE DATA
% Create a date array starting '01-Jan-2004'and ending '31-Dec-2009'
startDate = datenum('01-Jan-2004');
trainingDate = datenum('31-Dec-2008');
endDateTraining = datenum('31-Jan-2009');
endDate = datenum('31-Dec-2009');
interval = 1;
dateArray = datestr(startDate:interval:endDate);
dateNum = datenum(dateArray);


% Load DBLoadData.mat
load Data\DBLoadData.mat

% Calculate the peak load everyday from the data.SYSLoad
hourlyLoad = data.SYSLoad;
columns = size(hourlyLoad,1)/24;
rows = 24;
dailyPeakLoad = (max(reshape(hourlyLoad,[rows,columns])))';


% Previous 5 days peak load average
daily5dayHighAvg = (tsmovavg(dailyPeakLoad','s',3));
daily5dayHighAvg = [ NaN daily5dayHighAvg(1:end-1) ]';

% Peak Dew Point (Average of top 5 dew points in a day)
dewPntArray = data.DewPnt;
columns = size(dewPntArray,1)/24;
dewPntArray = reshape(dewPntArray,[rows,columns]);
dewPntArray = sort(dewPntArray,'descend');
dewPntArray = max(dewPntArray)';

% Peak Temperature (Average of top 5 temperatures in a day)
tempArray = data.DryBulb;
columns = size(tempArray,1)/24;
tempArray = reshape(tempArray,[rows,columns]);
tempArray = sort(tempArray,'descend');
tempArray = max(tempArray)';

% clear startDate endDate interval dateArray hourlyLoad columns rows;

% Previous 5 days peak temperature average
daily5dayTempAvg = (tsmovavg(tempArray','s',3));
daily5dayTempAvg = [ NaN daily5dayTempAvg(1:end-1) ]';

% Previous 5 days peak dew point average
daily5dayDewAvg = (tsmovavg(dewPntArray','s',3));
daily5dayDewAvg = [ NaN daily5dayDewAvg(1:end-1) ]';

% Previous Week Same Day Peak Load
prevWeekLoad = [ NaN NaN NaN NaN NaN NaN NaN dailyPeakLoad(1:end-7)' ]';

% Previous Week Same Day Peak Temp
prevWeekTemp = [ NaN NaN NaN NaN NaN NaN NaN tempArray(1:end-7)' ]';

% Previous Week Same Day Peak Dew Point
prevWeekDew = [ NaN NaN NaN NaN NaN NaN NaN dewPntArray(1:end-7)' ]';

% Previous Day Peak Load
prevDayLoad = [ NaN dailyPeakLoad(1:end-1)' ]';

% Previous Day Peak Temp
prevDayTemp = [ NaN tempArray(1:end-1)' ]';

% Previous Day Peak Dew Point
prevDayDew = [ NaN dewPntArray(1:end-1)' ]';


[num, text] = xlsread('F:\Project\Electricity Load & Price Forecasting\Data\Holidays.xls');
holidays = num(1:end);
holidays = x2mdate(holidays, 0);
dayOfWeek = weekday(dateNum);


%dayOfWeek(1:5)
% Non-business days
isWorkingDay = ~ismember(dateNum,holidays) & ~ismember(dayOfWeek,[1 7]);

clear holidays num text data;

X = [ daily5dayTempAvg daily5dayDewAvg daily5dayHighAvg dayOfWeek isWorkingDay tempArray dewPntArray prevWeekLoad prevWeekTemp prevWeekDew prevDayLoad prevDayTemp prevDayDew];


%% DECIDE THE TRAINING AND TESTING DATES
trainInd = dateNum <= trainingDate;
testInd = dateNum >= datenum('2009-01-01');

%% SEPARATE THE TRAINING AND TESTING DATA
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);
testX = X(testInd,:);
testY = dailyPeakLoad(testInd);

%% MULTIVARIATE LINEAR REGRESSION

beta = mvregress(trainX, trainY);
forecastLoadMVR = testX*beta;

%% GET THE MONTHLY FORECASTS AND ACTUAL LOADS, CALCULATE LOSSES

% January
forecastLoadMVRJan = forecastLoadMVR(1:31,:);
ActualLoadJan = testY(1:31,:);
err = ActualLoadJan-forecastLoadMVRJan;
errpct = abs(err)./ActualLoadJan*100;
MAPEJan = mean(errpct(~isinf(errpct)));



% February
forecastLoadMVRFeb = forecastLoadMVR(32:59,:);
ActualLoadFeb = testY(32:59,:);
err = ActualLoadFeb-forecastLoadMVRFeb;
errpct = abs(err)./ActualLoadFeb*100;
MAPEFeb = mean(errpct(~isinf(errpct)));

% March
forecastLoadMVRMar = forecastLoadMVR(60:90,:);
ActualLoadMar = testY(60:90,:);
err = ActualLoadMar-forecastLoadMVRMar;
errpct = abs(err)./ActualLoadMar*100;
MAPEMar = mean(errpct(~isinf(errpct)));

% April
forecastLoadMVRApr = forecastLoadMVR(91:120,:);
ActualLoadApr = testY(91:120,:);
err = ActualLoadApr-forecastLoadMVRApr;
errpct = abs(err)./ActualLoadApr*100;
MAPEApr = mean(errpct(~isinf(errpct)));

% May
forecastLoadMVRMay = forecastLoadMVR(121:151,:);
ActualLoadMay = testY(121:151,:);
err = ActualLoadMay-forecastLoadMVRMay;
errpct = abs(err)./ActualLoadMay*100;
MAPEMay = mean(errpct(~isinf(errpct)));

% June
forecastLoadMVRJun = forecastLoadMVR(152:181,:);
ActualLoadJun = testY(152:181,:);
err = ActualLoadJun-forecastLoadMVRJun;
errpct = abs(err)./ActualLoadJun*100;
MAPEJun = mean(errpct(~isinf(errpct)));

% July
forecastLoadMVRJul = forecastLoadMVR(182:212,:);
ActualLoadJul = testY(182:212,:);
err = ActualLoadJul-forecastLoadMVRJul;
errpct = abs(err)./ActualLoadJul*100;
MAPEJul = mean(errpct(~isinf(errpct)));

% August
forecastLoadMVRAug = forecastLoadMVR(213:243,:);
ActualLoadAug = testY(213:243,:);
err = ActualLoadAug-forecastLoadMVRAug;
errpct = abs(err)./ActualLoadAug*100;
MAPEAug = mean(errpct(~isinf(errpct)));

% September
forecastLoadMVRSep = forecastLoadMVR(244:273,:);
ActualLoadSep = testY(244:273,:);
err = ActualLoadSep-forecastLoadMVRSep;
errpct = abs(err)./ActualLoadSep*100;
MAPESep = mean(errpct(~isinf(errpct)));

% October
forecastLoadMVROct = forecastLoadMVR(274:304,:);
ActualLoadOct = testY(274:304,:);
err = ActualLoadOct-forecastLoadMVROct;
errpct = abs(err)./ActualLoadOct*100;
MAPEOct = mean(errpct(~isinf(errpct)));

% November 
forecastLoadMVRNov = forecastLoadMVR(305:334,:);
ActualLoadNov = testY(305:334,:);
err = ActualLoadNov-forecastLoadMVRNov;
errpct = abs(err)./ActualLoadNov*100;
MAPENov = mean(errpct(~isinf(errpct)));

% December
forecastLoadMVRDec = forecastLoadMVR(335:365,:);
ActualLoadDec = testY(335:365,:);
err = ActualLoadDec-forecastLoadMVRDec;
errpct = abs(err)./ActualLoadDec*100;
MAPEDec = mean(errpct(~isinf(errpct)));

% MAPEArr - Array containing all the monthly errors

MAPEArr = [ MAPEJan MAPEFeb MAPEMar MAPEApr MAPEMay MAPEJun MAPEJul MAPEAug MAPESep MAPEOct MAPENov MAPEDec ]';
