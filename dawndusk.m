%------------------------------Function DAWNDUSK()------------------------------
function [delay,srt,sst,mrt,mst,now_s,dnflag,lnflag,sunh]=dawndusk()
%DAWNDUSK:  Whether now is the dawn or dusk, which may lead to an acute light change, destroying the Cloud-Cover Judgement
%	INPUT:
%		None
%	OUTPUT:
%		delay:	How long can we leave the dawn or dusk, if not in that time, return 0.
%		srt:	the string of sunrise time, e.g. '06:31'
%		sst:	the string of sunset time, e.g. '17:55'
%		mrt:	the string of moonrise time e.g. '21:30'
%		mst:	the string of monnset time e.g. '10:25'
%		now_s:	time now from midnight
%		dnflag:	the flag of daytime or nighttime,0 for day and 1 for night
%		lnflag:	lunar night flag, a sign of MOON on the NIGHT sky '1' or not '0'
%	SUBFUNCTION:
%		DRAWPIC:	Draw the timerank of Cloud_Cover today
%	EXAMPLE:
%		[delay,srt,sst,mrt,mst,dnflag]=dawndusk()

%LOG:
%2012-10-03:	Complete
%2012-10-04:	Add dnflag variable
%2012-10-05:	Add moon rise time and moon set time from HKO by php SEDUCE
%2012-10-06:	Add DRAWPIC SUB during pause
%2012-10-07:	Add nt and lnflag for expjudge()
%2012-10-14:	Add sunheight caculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	global sunline;
	global c;%Get the clock data into a column vector im.g. c(1-6)->2012|8|14|22|12|32
	
	delay=0;
	dnflag=1;							%Default:Nighttime	
	lnflag=0;							%Default:Night without Moon
	if (str2num(sunline(3:4))~=c(3))				%If the day changed	
		fid1=fopen('parameter/sundata.txt','r');				
		for i=1:366
			sunline=fgetl(fid1);
			if str2num(sunline(1:2))==c(2)&str2num(sunline(4:5))==c(3)	%Get the right line of today
				break;
			end
		end
		fclose(fid1);
	end
	srh=str2num(sunline(7:8));
	srm=str2num(sunline(10:11));
	ssh=str2num(sunline(13:14));
	ssm=str2num(sunline(16:17));
	srt=sunline(7:11);
	sst=sunline(13:17);
	
	sr_s=srh*3600+srm*60;				%Get the seconds of sunrise to midnight	
	ss_s=ssh*3600+ssm*60;				%Get the seconds of sunset to midnight
	now_s=c(4)*3600+c(5)*60+c(6);			%Get the seconds now to midnight
	
	mrh=0;
	mrm=0;
	msh=0;
	msm=0;
	mrt='00:00';
	mst='00:00';
	fid1=fopen('parameter/Sun_N_Moon_Clock.dat','r');	
	while(feof(fid1)==0)
		moonline=fgetl(fid1);
		if(strcmp(moonline,'Moon Rise'))
			moonline=fgetl(fid1);
			mrh=str2num(moonline(1:2));
			mrm=str2num(moonline(4:5));
			mrt=moonline(1:5);
		elseif(strcmp(moonline,'Moon Set'))
			moonline=fgetl(fid1);
			msh=str2num(moonline(1:2));
			msm=str2num(moonline(4:5));
			mst=moonline(1:5);
		else
			continue;		
		end	
	end
	fclose(fid1);
	mr_s=mrh*3600+mrm*60;				%Get the seconds of moonrise to midnight	
	ms_s=msh*3600+msm*60;				%Get the seconds of moonset to midnight

	if sr_s<now_s & now_s<ss_s
		dnflag=0;				%Daytime		
	end
	
	if dnflag==1	
		if (mr_s<now_s)&(now_s<ms_s)
			lnflag=1;
		elseif(mr_s>ms_s)
			if(now_s>mr_s)
				lnflag=1;
			elseif(now_s<ms_s)
				lnflag=1;	
			end
		end	
	end

	lon=113.39*pi/180;
	lat=23.05*pi/180;

	Local_Midday=(sr_s+ss_s)/2;
	Local_Time=now_s-Local_Midday;
	Hour_Angle=Local_Time*7.27e-5;
	Day_Rank=30*(c(2)-1)+c(3);
	Dec=asin(0.398*sin(4.87+0.0175*Day_Rank+0.033*sin(0.0175*Day_Rank)));
	sunh=asin(sin(lat)*sin(Dec)+cos(lat)*cos(Dec)*cos(Hour_Angle))*180/pi;

