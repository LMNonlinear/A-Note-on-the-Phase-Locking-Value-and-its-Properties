
clc; clear all; close all;

addpath(genpath('F:\29.02.2012backup\Research Spring 2012\april\paper_draft\matlab_codes'));

load dataAllGoFiltbeta;
load dataAllNoGoFiltbeta;

idxTime = 70; %find((times<5)&(times>-5));
idxTimeVec = idxTime;%[idxTime-5:1:idxTime+5];

hilbertGoSingleTimeAll = []; hilbertNoGoSingleTimeAll = [];

for idxExp = [5 6 7 8 9 11 12 15 16 18]; %[1 2 3 4 10 13 14 17]; %[5 6 7 8 9 11 12 15 16 18];

nstr = num2str(idxExp);
if idxExp<10
    nstr = ['0' nstr];
end
goAllTime = dataAllGoFiltbeta{idxExp};
nTrialGo = size(goAllTime,3);
nogoAllTime = dataAllNoGoFiltbeta{idxExp};
nTrialNoGo = size(nogoAllTime,3);

zmGoAllTime = goAllTime - repmat(mean(goAllTime,3),[1 1 nTrialGo]);
zmNoGoAllTime = nogoAllTime - repmat(mean(nogoAllTime,3),[1 1 nTrialNoGo]);

hilbertGo = zeros(size(zmGoAllTime)); % 120 x 15 x 300
hilbertNoGo = zeros(size(zmNoGoAllTime));

% compute Hilbert transform
for idxChannel = 1:15
    tempGo = hilbert(squeeze(zmGoAllTime(:,idxChannel,:)));
    tempNoGo = hilbert(squeeze(zmNoGoAllTime(:,idxChannel,:)));
    
    hilbertGo(:,idxChannel,:) = tempGo;
    hilbertNoGo(:,idxChannel,:) = tempNoGo;
end

hilbertGoSingleTimeAll = cat(3,hilbertGoSingleTimeAll,hilbertGo(idxTimeVec,:,:));
hilbertNoGoSingleTimeAll = cat(3,hilbertNoGoSingleTimeAll,hilbertNoGo(idxTimeVec,:,:));
end
covMatGo = cov(squeeze(hilbertGoSingleTimeAll)');
covMatNoGo = cov(squeeze(hilbertNoGoSingleTimeAll)');

%for idxChannel = 1:15;

goPhaseAllChan = squeeze(angle(hilbertGoSingleTimeAll(:,:,:)));
nogoPhaseAllChan = squeeze(angle(hilbertNoGoSingleTimeAll(:,:,:)));

goPhaseDiff = zeros(15,15,size(goPhaseAllChan,2));
nogoPhaseDiff = zeros(15,15,size(nogoPhaseAllChan,2));

for idxX = 1:14;
    for idxY = idxX+1:15
        tempDiffGo = goPhaseAllChan(idxX,:) - goPhaseAllChan(idxY,:);
        tempDiffGo(find(tempDiffGo>pi)) = tempDiffGo(find(tempDiffGo>pi)) - 2*pi;
        tempDiffGo(find(tempDiffGo<-pi)) = tempDiffGo(find(tempDiffGo<-pi)) + 2*pi;

        goPhaseDiff(idxX,idxY,:) = tempDiffGo;
        

        
%         tempDiffNoGo = nogoPhaseAllChan(idxX,:) - nogoPhaseAllChan(idxY,:);
%         tempDiffNoGo(find(tempDiffNoGo>pi)) = tempDiffNoGo(find(tempDiffNoGo>pi)) - 2*pi;
%         tempDiffNoGo(find(tempDiffNoGo<-pi)) = tempDiffNoGo(find(tempDiffNoGo<-pi)) + 2*pi;
% 
%         nogoPhaseDiff(idxX,idxY,:) = tempDiffNoGo;
    end
end

idxMat = [1 7; 1 8; 4 7; 4 8; 7 8]; %[2 3; 2 5; 3 5]; %[1 7; 1 8; 4 7; 4 8; 7 8];

for i = 1:size(idxMat,1);
i
idxX = idxMat(i,1);
idxY = idxMat(i,2);
binsize = 64;
[valGo,postGo] = hist(squeeze(goPhaseDiff(idxX,idxY,:)),binsize);

x = [-pi:0.01:pi];
 R12 = -covMatGo(idxX,idxY)/sqrt(covMatGo(idxX,idxX)*covMatGo(idxY,idxY));
 gamma = abs(R12)*cos(x - (angle(R12)));
 pdf_circgauss = (1-abs(R12)^2)./(2*pi*(1-gamma.^2)).*(1-(gamma.*acos(gamma))./sqrt(1-gamma.^2));
 
 addpath(['F:\29.02.2012backup\old research\RESEARCH SPG 10\PROJECTS-June 2010'...
    '\Von mises\CircStat'])
 coupling_ml = circ_kappa(squeeze(goPhaseDiff(idxX,idxY,:))); % abs(Kvm(1,2)); %
mean_ml = circ_mean(squeeze(goPhaseDiff(idxX,idxY,:)));
pdf_vm = 1/(2*pi*besseli(0,coupling_ml))*exp(coupling_ml * cos(x - mean_ml));

 
valGo = valGo/(trapz(postGo,valGo));
addpath(genpath(['F:\29.02.2012backup\Research Spring 2012\February\ISBI_2012\matlab codes']))
N = size(squeeze(goPhaseDiff(idxX,idxY,:)),1);
for index = 1:N
    index;
    cdf_cg(index) = randarb(x,pdf_circgauss);
    cdf_vm(index) = randarb(x,pdf_vm);
    
end

figure;
% subplot(1,2,1)
qqplot(squeeze(goPhaseDiff(idxX,idxY,:)),cdf_cg)
fontsize = 15;
xlabel('Empirical quantile of relative phase','FontSize',fontsize)
ylabel('Analytical quantile of relative phase (CG)','FontSize',fontsize)
set(gca,'Xtick',[-3:3:3]); set(gca,'XTickLabel',[-3:3:3],'FontSize',fontsize);
set(gca,'Ytick',[-3:3:3]); set(gca,'YTickLabel',[-3:3:3],'FontSize',fontsize);

% subplot(1,2,2)
hold on;
qqplotred(squeeze(goPhaseDiff(idxX,idxY,:)),cdf_vm)
fontsize = 15;
xlabel('Empirical quantile of relative phase','FontSize',fontsize)
ylabel('Analytical quantile of relative phase (VM)','FontSize',fontsize)
set(gca,'Xtick',[-3:3:3]); set(gca,'XTickLabel',[-3:3:3]);
set(gca,'Ytick',[-3:3:3]); set(gca,'YTickLabel',[-3:3:3])


% subplot(1,3,i) 
% figure;
% bar(postGo,valGo);
% hold on;
% plot(postGo,pdf_circgauss,'Color','r','LineWidth',2);
% plot(postGo,pdf_vm,'Color','g','LineWidth',2);
% legend('Empirical','Gaussian fit','von Mises fit')
% axis([-4 4 0 1])
 title(sprintf('Electrodes %d and %d',idxX,idxY));
% axis square;
end






















