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
daily5dayHighAvg = (tsmovavg(dailyPeakLoad','s',5));
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

clear startDate endDate interval dateArray hourlyLoad columns rows;

% Previous 5 days peak temperature average
daily5dayTempAvg = (tsmovavg(tempArray','s',5));
daily5dayTempAvg = [ NaN daily5dayTempAvg(1:end-1) ]';

% Previous 5 days peak dew point average
daily5dayDewAvg = (tsmovavg(dewPntArray','s',5));
daily5dayDewAvg = [ NaN daily5dayDewAvg(1:end-1) ]';

[num, text] = xlsread('F:\Project\Electricity Load & Price Forecasting\Data\Holidays.xls');
holidays = num(1:end);
holidays = x2mdate(holidays, 0);
dayOfWeek = weekday(dateNum);

%dayOfWeek(1:5)
% Non-business days
isWorkingDay = ~ismember(dateNum,holidays) & ~ismember(dayOfWeek,[1 7]);

clear holidays num text data;

X = [daily5dayTempAvg daily5dayDewAvg daily5dayHighAvg dayOfWeek isWorkingDay tempArray dewPntArray ];



trainInd = dateNum < datenum('2008-01-01');

% trainX will consist of the rows whose corresponding trainInd is true
trainX = X(trainInd,:);

% same goes for trainy
trainY = dailyPeakLoad(trainInd);

testInd = dateNum >= datenum('2008-01-01');
testX = X(testInd,:);
testY = dailyPeakLoad(testInd);
testDates = dateNum(testInd);

disp('hello');
reTrain = true;
if reTrain || ~exist('Models\NNModel.mat', 'file')
    net = newfit(trainX', trainY', 20);
    net.performFcn = 'mae';
    net = train(net, trainX', trainY');
    save Models\NNModel.mat net
else
    load Models\NNModel.mat
end

forecastLoad = sim(net, testX')';

err = testY-forecastLoad;
fitPlot(testDates, [testY forecastLoad], err);


errpct = abs(err)./testY*100;

MAE = mean(abs(err));
MAPE = mean(errpct(~isinf(errpct)));

fprintf('Mean Absolute Percent Error (MAPE): %0.2f%% \nMean Absolute Error (MAE): %0.2f MWh\nDaily Peak MAPE: %0.2f%%\n',...
    MAPE, MAE, mean(errpct))

testY(1:10)
forecastLoad(1:10)
