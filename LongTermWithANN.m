%% INPUT DATA
% We load 'DBLoadData.mat' which consists of the following fields
%   1.  Date
%   2.  Hour ( 1 to 24 )
%   3.  Dry Bulb Temperature at the hour
%   4.  Dew Point at the hour
%   5.  System Load at the hour

%% OUTPUT DATA
%   After training, we obtain the following outputs
%
%   1.  ActualLoadOfDay - A map which tells us the actual peak load of any day
%       over the year. For example:
%       ActualLoadOfDay('Sun') returns the actual peak load of the all Sundays
%       in a year.
%
%   2.  forecastOfDay - A map which tells us the forecasted peak load of any day
%       over the year. For example:
%       forecastOfDay('Sun') returns the forecasted peak load of the all Sundays
%       in a year.
%
%   3.  ActualLoadOfMonth - A map which tells us the actual peak load of all days
%       in a month. For example:
%       ActualLoadOfMonth('Jan') returns the actual peak load of the all days in
%       the month of Jan
%
%   4.  forecastOfMonth - A map which tells us the forecasted peak load of all days
%       in a month. For example:
%       forecastOfMonth('Jan') returns the forecasted peak load of the all days in
%       the month of Jan.
%
%   5.  MAPEDaily - A vector containing the Mean Average Percentage Error
%       according to the day.
%
%   6.  MAPEMonthly - A vector containing the Mean Average Percentage Error
%       according to the Month.




%% ARRANGING THE DATA
% Create a date array starting '01-Jan-2004'and ending '31-Dec-2009'
startDate = datenum('01-Jan-2004');
endDate = datenum('31-Dec-2009');
interval = 1;
dateArray = datestr(startDate:interval:endDate);
dateNum = datenum(dateArray);

endDateTraining = datenum('31-Jan-2009');


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


X = [ daily5dayTempAvg daily5dayDewAvg daily5dayHighAvg dayOfWeek isWorkingDay tempArray dewPntArray prevWeekLoad prevWeekTemp prevWeekDew prevDayLoad prevDayTemp prevDayDew];

clear holidays num text data columns;
clear daily5dayTempAvg daily5dayDewAvg daily5dayHighAvg isWorkingDay tempArray dewPntArray prevWeekLoad prevWeekTemp prevWeekDew prevDayLoad prevDayTemp prevDayDew;

%% Days in a Month
daysInMonth = containers.Map({'Jan','Feb','Mar','Apr','May','Jun','Jul', 'Aug', 'Sep','Oct','Nov','Dec'},{31,28,31,30,31,30,31,31,30,31,30,31});


%% REASON FOR DUPLICATING A LOT OF CODE
% A lot of code is duplicated because I am training a different neural
% network for the forecast of every month's load. A different approach may
% require just creating one neural network and training it over a for loop.
% I, however, wanted to have unique control over each month's prediction
% so that the parameters of the network could be modified depending on the
% error of the particular month.

%% Network Parameters
reTrainJan = false;
reTrainFeb = false;
reTrainMar = false;
reTrainApr = false;
reTrainMay = false;
reTrainJun = false;
reTrainJul = false;
reTrainAug = false;
reTrainSep = false;
reTrainOct = false;
reTrainNov = false;
reTrainDec = false;

% Number of neurons in hidden layer (only 1) is set by hit and trial for
% minimizing the error
networkConfigJan = 35;
networkConfigFeb = 30;
networkConfigMar = 40;
networkConfigApr = 35;
networkConfigMay = 40;
networkConfigJun = 25;
networkConfigJul = 35;
networkConfigAug = 35;
networkConfigSep = 50;
networkConfigOct = 35;
networkConfigNov = 35;
networkConfigDec = 45;


%% FORECAST LOADS FOR JANUARY
% We are forecasting the peak loads for each day of the next month,
% by training the neural network up to the preceding month

% Last day of training
lastTrainingDate = datenum('31-Dec-2008');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainJan || ~exist('Models\NNModelJan.mat', 'file')
    netJan = newfit(trainX', trainY', networkConfigJan);
    netJan.performFcn = 'mae';
    netJan = trainlm(netJan, trainX', trainY');
    save Models\NNModelJan.mat netJan
else
    load Models\NNModelJan.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Jan') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadJan = testY;
% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadJan = sim(netJan, testX')';
errJan = testY - forecastLoadJan;
errpct = abs(errJan)./testY*100;
MAPEJan = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR FEBRUARY
% Last day of training
lastTrainingDate = datenum('31-Jan-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainFeb || ~exist('Models\NNModelFeb.mat', 'file')
    netFeb = newfit(trainX', trainY', networkConfigFeb);
    netFeb.performFcn = 'mae';
    netFeb = trainlm(netFeb, trainX', trainY');
    save Models\NNModelFeb.mat netFeb
else
    load Models\NNModelFeb.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Feb') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadFeb = testY;
% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadFeb = sim(netFeb, testX')';
errFeb = testY - forecastLoadFeb;
errpct = abs(errFeb)./testY*100;
MAPEFeb = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR MARCH
% Last day of training
lastTrainingDate = datenum('28-Feb-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainMar || ~exist('Models\NNModelMar.mat', 'file')
    netMar = newfit(trainX', trainY', networkConfigMar);
    netMar.performFcn = 'mae';
    netMar = trainlm(netMar, trainX', trainY');
    save Models\NNModelMar.mat netMar
else
    load Models\NNModelMar.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Mar') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadMar = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadMar = sim(netMar, testX')';
errMar = testY - forecastLoadMar;
errpct = abs(errMar)./testY*100;
MAPEMar = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR APRIL
% Last day of training
lastTrainingDate = datenum('31-Mar-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainApr || ~exist('Models\NNModelApr.mat', 'file')
    netApr = newfit(trainX', trainY', networkConfigApr);
    netApr.performFcn = 'mae';
    netApr = trainlm(netApr, trainX', trainY');
    save Models\NNModelApr.mat netApr
else
    load Models\NNModelApr.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Apr') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadApr = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadApr = sim(netApr, testX')';
errApr = testY - forecastLoadApr;
errpct = abs(errApr)./testY*100;
MAPEApr = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR MAY
% Last day of training
lastTrainingDate = datenum('30-Apr-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainMay || ~exist('Models\NNModelMay.mat', 'file')
    netMay = newfit(trainX', trainY', networkConfigMay);
    netMay.performFcn = 'mae';
    netMay = trainlm(netMay, trainX', trainY');
    save Models\NNModelMay.mat netMay
else
    load Models\NNModelMay.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('May') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadMay = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadMay = sim(netMay, testX')';
errMay = testY - forecastLoadMay;
errpct = abs(errMay)./testY*100;
MAPEMay = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR JUNE
% Last day of training
lastTrainingDate = datenum('31-May-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainJun || ~exist('Models\NNModelJun.mat', 'file')
    netJun = newfit(trainX', trainY', networkConfigJun);
    netJun.performFcn = 'mae';
    netJun = trainlm(netJun, trainX', trainY');
    save Models\NNModelJun.mat netJun
else
    load Models\NNModelJun.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Jun') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadJun = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadJun = sim(netJun, testX')';
errJun = testY - forecastLoadJun;
errpct = abs(errJun)./testY*100;
MAPEJun = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR JULY
% Last day of training
lastTrainingDate = datenum('30-Jun-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainJul || ~exist('Models\NNModelJul.mat', 'file')
    netJul = newfit(trainX', trainY', networkConfigJul);
    netJul.performFcn = 'mae';
    netJul = trainlm(netJul, trainX', trainY');
    save Models\NNModelJul.mat netJul
else
    load Models\NNModelJul.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Jul') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadJul = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadJul = sim(netJul, testX')';
errJul = testY - forecastLoadJul;
errpct = abs(errJul)./testY*100;
MAPEJul = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR AUGUST
% Last day of training
lastTrainingDate = datenum('31-July-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainAug || ~exist('Models\NNModelAug.mat', 'file')
    netAug = newfit(trainX', trainY', networkConfigAug);
    netAug.performFcn = 'mae';
    netAug = trainlm(netAug, trainX', trainY');
    save Models\NNModelAug.mat netAug
else
    load Models\NNModelAug.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Aug') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadAug = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadAug = sim(netAug, testX')';
errAug = testY - forecastLoadAug;
errpct = abs(errAug)./testY*100;
MAPEAug = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR SEPTEMBER
% Last day of training
lastTrainingDate = datenum('31-Aug-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainSep || ~exist('Models\NNModelSep.mat', 'file')
    netSep = newfit(trainX', trainY', networkConfigSep);
    netSep.performFcn = 'mae';
    netSep = trainlm(netSep, trainX', trainY');
    save Models\NNModelSep.mat netSep
else
    load Models\NNModelSep.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Sep') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadSep = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadSep = sim(netSep, testX')';
errSep = testY - forecastLoadSep;
errpct = abs(errSep)./testY*100;
MAPESep = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR OCTOBER
% Last day of training
lastTrainingDate = datenum('30-Sep-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainOct || ~exist('Models\NNModelOct.mat', 'file')
    netOct = newfit(trainX', trainY', networkConfigOct);
    netOct.performFcn = 'mae';
    netOct = trainlm(netOct, trainX', trainY');
    save Models\NNModelOct.mat netOct
else
    load Models\NNModelOct.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Oct') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadOct = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadOct = sim(netOct, testX')';
errOct = testY - forecastLoadOct;
errpct = abs(errOct)./testY*100;
MAPEOct = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR NOVEMBER
% Last day of training
lastTrainingDate = datenum('31-Oct-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainNov || ~exist('Models\NNModelNov.mat', 'file')
    netNov = newfit(trainX', trainY', networkConfigNov);
    netNov.performFcn = 'mae';
    netNov = trainlm(netNov, trainX', trainY');
    save Models\NNModelNov.mat netNov
else
    load Models\NNModelNov.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Nov') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadNov = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadNov = sim(netNov, testX')';
errNov = testY - forecastLoadNov;
errpct = abs(errNov)./testY*100;
MAPENov = mean(errpct(~isinf(errpct)));


%% FORECAST LOADS FOR DECEMBER
% Last day of training
lastTrainingDate = datenum('30-Nov-2009');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainDec || ~exist('Models\NNModelDec.mat', 'file')
    netDec = newfit(trainX', trainY', networkConfigDec);
    netDec.performFcn = 'mae';
    netDec = trainlm(netDec, trainX', trainY');
    save Models\NNModelDec.mat netDec
else
    load Models\NNModelDec.mat
end

% Index for the testing Data
startingInd = find(trainInd == 0, 1, 'first');
endingInd = startingInd + daysInMonth('Dec') - 1 ;

% Testing Data
testX = X(startingInd:endingInd,:);
testY = dailyPeakLoad(startingInd:endingInd,:);
actualLoadDec = testY;

% Calculate the Forcast Load and the Mean Absolute Percentage Error
forecastLoadDec = sim(netDec, testX')';
errDec = testY - forecastLoadDec;
errpct = abs(errDec)./testY*100;
MAPEDec = mean(errpct(~isinf(errpct)));

%% Monthly MAPE
MAPEMonthly = [ MAPEJan MAPEFeb MAPEMar MAPEApr MAPEMay MAPEJun MAPEJul MAPEAug MAPESep MAPEOct MAPENov MAPEDec ]';

%% Clear some of the variables

clear MAPEJan MAPEFeb MAPEMar MAPEApr MAPEMay MAPEJun MAPEJul MAPEAug MAPESep MAPEOct MAPENov MAPEDec;
clear errJan errFeb errMar errApr errMay errJun errJul errAug errSep errOct errNov errDec;
clear networkConfigGlobal reTrainJan reTrainFeb reTrainMar reTrainApr reTrainMay reTrainJun reTrainJul ... 
    reTrainAug reTrainSep reTrainOct reTrainNov reTrainDec;
clear networkConfigJan networkConfigFeb networkConfigMar networkConfigApr networkConfigMay networkConfigJun ...
    networkConfigJul networkConfigAug networkConfigSep;
clear networkConfigOct networkConfigNov networkConfigDec;
clear netJan netFeb netMar netApr netMay netJun netJul netAug netSep netOct netNov netDec;
clear trainX trainY trainInd testX testY startingInd startDate rows lastTrainingDate interval hourlyLoad ...
    errpct endingInd endDateTraining endDate daysInMonth dateNum;
clear dateArray dailyPeakLoad X;

%% Combine all actual daily peak loads into a vector
dailyPeakLoadTest = [actualLoadJan' actualLoadFeb' actualLoadMar' actualLoadApr' actualLoadMay' actualLoadJun' actualLoadJul' ...
    actualLoadAug' actualLoadSep' actualLoadOct' actualLoadNov' actualLoadDec' ]';

dailyPeakLoadForecast = [forecastLoadJan' forecastLoadFeb' forecastLoadMar' forecastLoadApr' forecastLoadMay' forecastLoadJun' ...
    forecastLoadJul' forecastLoadAug' forecastLoadSep' forecastLoadOct' forecastLoadNov' forecastLoadDec' ]';

forecastOfMonth = containers.Map({'Jan','Feb','Mar','Apr','May','Jun','Jul', 'Aug', 'Sep','Oct','Nov','Dec'},{forecastLoadJan, forecastLoadFeb, ...
    forecastLoadMar, forecastLoadApr, forecastLoadMay, forecastLoadJun, forecastLoadJul, forecastLoadAug, forecastLoadSep, forecastLoadOct, ...
    forecastLoadNov, forecastLoadDec});
ActualLoadOfMonth = containers.Map({'Jan','Feb','Mar','Apr','May','Jun','Jul', 'Aug', 'Sep','Oct','Nov','Dec'},{actualLoadJan, actualLoadFeb, ...
    actualLoadMar, actualLoadApr, actualLoadMay, actualLoadJun, actualLoadJul, actualLoadAug, actualLoadSep, actualLoadOct, ...
    actualLoadNov, actualLoadDec});

clear forecastLoadJan forecastLoadFeb forecastLoadMar forecastLoadApr forecastLoadMay forecastLoadJun forecastLoadJul ...
    forecastLoadAug forecastLoadSep forecastLoadOct forecastLoadNov forecastLoadDec;
clear actualLoadJan actualLoadFeb actualLoadMar actualLoadApr actualLoadMay actualLoadJun actualLoadJul actualLoadAug ...
    actualLoadSep actualLoadOct actualLoadNov actualLoadDec;

%% Error by WeekDay
% Label the day of the week for each day in the forecast year 2009
dayOfWeek = weekday(datenum(datestr(datenum('01-Jan-2009'):1:datenum('31-Dec-2009'))));

% SUNDAY ERROR
findSun = (dayOfWeek == 1);
SundayLoadTest = dailyPeakLoadTest(findSun,:);
SundayLoadForecast = dailyPeakLoadForecast(findSun,:);
err = SundayLoadTest - SundayLoadForecast;
errpct = abs(err)./SundayLoadTest*100;
MAPESun = mean(errpct(~isinf(errpct)));

% MONDAY ERROR
findMon = (dayOfWeek == 2);
MondayLoadTest = dailyPeakLoadTest(findMon,:);
MondayLoadForecast = dailyPeakLoadForecast(findMon,:);
err = MondayLoadTest - MondayLoadForecast;
errpct = abs(err)./MondayLoadTest*100;
MAPEMon = mean(errpct(~isinf(errpct)));

% TUESDAY ERROR
findTues = (dayOfWeek == 3);
TuesdayLoadTest = dailyPeakLoadTest(findTues,:);
TuesdayLoadForecast = dailyPeakLoadForecast(findTues,:);
err = TuesdayLoadTest - TuesdayLoadForecast;
errpct = abs(err)./TuesdayLoadTest*100;
MAPETues = mean(errpct(~isinf(errpct)));

% WEDNESDAY ERROR
findWed = (dayOfWeek == 4);
WeddayLoadTest = dailyPeakLoadTest(findWed,:);
WeddayLoadForecast = dailyPeakLoadForecast(findWed,:);
err = WeddayLoadTest - WeddayLoadForecast;
errpct = abs(err)./WeddayLoadTest*100;
MAPEWed = mean(errpct(~isinf(errpct)));

% THURSDAY ERROR
findThur = (dayOfWeek == 5);
ThurdayLoadTest = dailyPeakLoadTest(findThur,:);
ThurdayLoadForecast = dailyPeakLoadForecast(findThur,:);
err = ThurdayLoadTest - ThurdayLoadForecast;
errpct = abs(err)./ThurdayLoadTest*100;
MAPEThur = mean(errpct(~isinf(errpct)));

% FRIDAY ERROR
findFri = (dayOfWeek == 6);
FridayLoadTest = dailyPeakLoadTest(findFri,:);
FridayLoadForecast = dailyPeakLoadForecast(findFri,:);
err = FridayLoadTest - FridayLoadForecast;
errpct = abs(err)./FridayLoadTest*100;
MAPEFri = mean(errpct(~isinf(errpct)));

% SATURDAY ERROR
findSat = (dayOfWeek == 7);
SatdayLoadTest = dailyPeakLoadTest(findSat,:);
SatdayLoadForecast = dailyPeakLoadForecast(findSat,:);
err = SatdayLoadTest - SatdayLoadForecast;
errpct = abs(err)./SatdayLoadTest*100;
MAPESat = mean(errpct(~isinf(errpct)));


MAPEDaily = [MAPESun MAPEMon MAPETues MAPEWed MAPEThur MAPEFri MAPESat ]';

forecastOfDay = containers.Map({'Sun','Mon','Tues','Wed','Thur','Fri','Sat'},{SundayLoadForecast, MondayLoadForecast, ...
    TuesdayLoadForecast, WeddayLoadForecast, ThurdayLoadForecast, FridayLoadForecast, SatdayLoadForecast});
ActualLoadOfDay = containers.Map({'Sun','Mon','Tues','Wed','Thur','Fri','Sat'},{SundayLoadTest, MondayLoadTest, ...
    TuesdayLoadTest, WeddayLoadTest, ThurdayLoadTest, FridayLoadTest, SatdayLoadTest});

clear SundayLoadTest MondayLoadTest TuesdayLoadTest WeddayLoadTest ThurdayLoadTest FridayLoadTest SatdayLoadTest;
clear SundayLoadForecast MondayLoadForecast TuesdayLoadForecast WeddayLoadForecast ThurdayLoadForecast FridayLoadForecast SatdayLoadForecast;
clear findSun findMon findTues findWed findThur findFri findSat err errpct;
clear MAPESun MAPEMon MAPETues MAPEWed MAPEThur MAPEFri MAPESat;
clear dailyPeakLoadTest dailyPeakLoadForecast dayOfWeek;
