%% ARRANGING THE DATA
% Create a date array starting '01-Jan-2004'and ending '31-Dec-2009'
startDate = datenum('01-Jan-2004');
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


X = [ daily5dayTempAvg daily5dayDewAvg daily5dayHighAvg dayOfWeek isWorkingDay tempArray dewPntArray prevWeekLoad prevWeekTemp ...
    prevWeekDew prevDayLoad prevDayTemp prevDayDew];



%% PRINCIPAL COMPONENT ANALYSIS

% Initial 7 training sets are lost because NaN was present in some of the
% fields. Thus, we are left with 'datenum('31-Dec-2008') -
% datenum('07-Jan-2004')' training sets ( 1820 ). The rest are used for
% testing purposes 

X = X(8:end,:);
dailyPeakLoad = dailyPeakLoad( 8:end,:);
dateNum = dateNum(8:end,:);

[pn,meanp,stdp] = prestd(X');
[ptrans,transMat] = prepca(pn,0.01);

ptrans = ptrans';
X = ptrans;

noOfRows = datenum('31-Dec-2008') - datenum('07-Jan-2004');

%% Develop the training data
% trainX = ptrans(1:noOfRows,:);
% 
% 
% testX = ptrans( noOfRows + 1:end,:);

clear holidays num text data columns;
clear daily5dayTempAvg daily5dayDewAvg daily5dayHighAvg isWorkingDay tempArray dewPntArray prevWeekLoad prevWeekTemp prevWeekDew ...
    prevDayLoad prevDayTemp prevDayDew;

%% Days in a Month
daysInMonth = containers.Map({'Jan','Feb','Mar','Apr','May','Jun','Jul', 'Aug', 'Sep','Oct','Nov','Dec'},{31,28,31,30,31,30,31,31,30,31,30,31});

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
networkConfigJan = 25;
networkConfigFeb = 30;
networkConfigMar = 25;
networkConfigApr = 25;
networkConfigMay = 25;
networkConfigJun = 25;
networkConfigJul = 25;
networkConfigAug = 35;
networkConfigSep = 25;
networkConfigOct = 25;
networkConfigNov = 25;
networkConfigDec = 25;


%% FORECAST LOADS FOR JANUARY
% We are forecasting the peak loads for each day of the next month,
% by training the neural network up to the preceding month

% Last day of training
lastTrainingDate = datenum('31-Dec-2008');

% Vector of boolean values with a '1' for every date preceding the 
% lastTrainingDate. Used to index into the data set
trainInd = dateNum <= lastTrainingDate;
jan = trainInd;

% Obtain the training data
trainX = X(trainInd,:);
trainY = dailyPeakLoad(trainInd);

% Train the neural network
if reTrainJan || ~exist('ModelsPCA\NNModelJan.mat', 'file')
    netJan = newfit(trainX', trainY', networkConfigJan);
    netJan.performFcn = 'mae';
    netJan = trainlm(netJan, trainX', trainY');
    save ModelsPCA\NNModelJan.mat netJan
else
    load ModelsPCA\NNModelJan.mat
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
if reTrainFeb || ~exist('ModelsPCA\NNModelFeb.mat', 'file')
    netFeb = newfit(trainX', trainY', networkConfigFeb);
    netFeb.performFcn = 'mae';
    netFeb = trainlm(netFeb, trainX', trainY');
    save ModelsPCA\NNModelFeb.mat netFeb
else
    load ModelsPCA\NNModelFeb.mat
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
if reTrainMar || ~exist('ModelsPCA\NNModelMar.mat', 'file')
    netMar = newfit(trainX', trainY', networkConfigMar);
    netMar.performFcn = 'mae';
    netMar = trainlm(netMar, trainX', trainY');
    save ModelsPCA\NNModelMar.mat netMar
else
    load ModelsPCA\NNModelMar.mat
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
if reTrainApr || ~exist('ModelsPCA\NNModelApr.mat', 'file')
    netApr = newfit(trainX', trainY', networkConfigApr);
    netApr.performFcn = 'mae';
    netApr = trainlm(netApr, trainX', trainY');
    save ModelsPCA\NNModelApr.mat netApr
else
    load ModelsPCA\NNModelApr.mat
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
if reTrainMay || ~exist('ModelsPCA\NNModelMay.mat', 'file')
    netMay = newfit(trainX', trainY', networkConfigMay);
    netMay.performFcn = 'mae';
    netMay = trainlm(netMay, trainX', trainY');
    save ModelsPCA\NNModelMay.mat netMay
else
    load ModelsPCA\NNModelMay.mat
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
if reTrainJun || ~exist('ModelsPCA\NNModelJun.mat', 'file')
    netJun = newfit(trainX', trainY', networkConfigJun);
    netJun.performFcn = 'mae';
    netJun = trainlm(netJun, trainX', trainY');
    save ModelsPCA\NNModelJun.mat netJun
else
    load ModelsPCA\NNModelJun.mat
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
if reTrainJul || ~exist('ModelsPCA\NNModelJul.mat', 'file')
    netJul = newfit(trainX', trainY', networkConfigJul);
    netJul.performFcn = 'mae';
    netJul = trainlm(netJul, trainX', trainY');
    save ModelsPCA\NNModelJul.mat netJul
else
    load ModelsPCA\NNModelJul.mat
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
if reTrainAug || ~exist('ModelsPCA\NNModelAug.mat', 'file')
    netAug = newfit(trainX', trainY', networkConfigAug);
    netAug.performFcn = 'mae';
    netAug = trainlm(netAug, trainX', trainY');
    save ModelsPCA\NNModelAug.mat netAug
else
    load ModelsPCA\NNModelAug.mat
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
if reTrainSep || ~exist('ModelsPCA\NNModelSep.mat', 'file')
    netSep = newfit(trainX', trainY', networkConfigSep);
    netSep.performFcn = 'mae';
    netSep = trainlm(netSep, trainX', trainY');
    save ModelsPCA\NNModelSep.mat netSep
else
    load ModelsPCA\NNModelSep.mat
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
if reTrainOct || ~exist('ModelsPCA\NNModelOct.mat', 'file')
    netOct = newfit(trainX', trainY', networkConfigOct);
    netOct.performFcn = 'mae';
    netOct = trainlm(netOct, trainX', trainY');
    save ModelsPCA\NNModelOct.mat netOct
else
    load ModelsPCA\NNModelOct.mat
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
if reTrainNov || ~exist('ModelsPCA\NNModelNov.mat', 'file')
    netNov = newfit(trainX', trainY', networkConfigNov);
    netNov.performFcn = 'mae';
    netNov = trainlm(netNov, trainX', trainY');
    save ModelsPCA\NNModelNov.mat netNov
else
    load ModelsPCA\NNModelNov.mat
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
if reTrainDec || ~exist('ModelsPCA\NNModelDec.mat', 'file')
    netDec = newfit(trainX', trainY', networkConfigDec);
    netDec.performFcn = 'mae';
    netDec = trainlm(netDec, trainX', trainY');
    save ModelsPCA\NNModelDec.mat netDec
else
    load ModelsPCA\NNModelDec.mat
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



