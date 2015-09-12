function take_time_series()
%DRAWPIC:  DRAW THE TIMESERIES OF CLOUDCOVER TODAY
%	INPUT:
%		y:	year
%		m:	month
%		d:	day
%		now_s:	seconds from midnight
%	OUTPUT:
%		None
%	EXAMPLE:
%		drawpic()

%LOG:
%2012-10-04:	Complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	global c;	
	clear all;
	close all;
	echo off;	
	now_s=c(4)*3600+c(5)*60+c(6);
	minute=fix(now_s/60);
	cloud_rank(1440)=NaN;
	cloud_rank(:)=NaN;
	s=['/home/eesael/wx/cloud/data/',int2str(c(1)),full(c(2)),full(c(3)),'.txt'];
	fid1=fopen(s,'r');
	while(feof(fid1)==0)
		line=fgetl(fid1);
		rmin=str2num(line(9:10))*60+str2num(line(11:12))+1;
		cloud_rank(rmin)=str2num(line(16:21));
		if cloud_rank(rmin)<0
			cloud_rank(rmin)=NaN;
		end				
	end	
	font_size=12;
	stem(cloud_rank*10,'.');
	axis([0 1440 0 10]);
	set(gca,'xtick',1:60:1441,'xticklabel',(0:60:1441)/60);
	ylabel('Cloud Cover in 10Div Mode');
	xlabel('Hour');
	title(['Cloud Cover TimeSeries (',int2str(c(1)),'/',full(c(2)),'/',full(c(3)),')']);
	set(get(gca,'XLabel'),'FontSize',font_size);
	set(get(gca,'YLabel'),'FontSize',font_size);
	set(get(gca,'title'),'FontSize',14);

function str=full(x)
%FULL:Fulfill the one num to format as '0X' such as '05'  
%	INPUT:
%		x:	the number that need to be fulfilled
%	OUTPUT:
%		str:	the filled string as '02'
%	EXAMPLE:
%		str=full(x)

%LOG:
%2012-10-04:	Complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if(x<10)
		str=['0',int2str(x)];	
	else	
		str=int2str(x);
	end
