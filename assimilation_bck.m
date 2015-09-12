%------------------------------Function 	ASSIMILATION()------------------------------
function bca=assimilation()
%ASSIMILATION: Judge the basic cloud cover condition by satellite MTSAT and ground observation of ZGGG(METARs)
%	INPUT:
%
%	OUTPUT:
%		bca:	background cloud cover caculated by satellite MTSAT and ground observation of ZGGG(METARs)
%	SUBFUNCION:
%		METARS:	Read and process the metar of ZGGG
%	EXAMPLE:
%		bca=assimilation()	

%LOG:
%2013-01-23:	Completed METARs method
%2013-05-24:	Update METARs method to a reasonable condition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	fprintf('        >>>>  Threshold Judgement, Assimilation module...\n')
	qflag=0;	
	[bca,qflag]=metars();
	if (bca==-1)|(qflag==1)
		
		try							%Catch the metar, return if failed
			fprintf('        >>>>  Assimilation Request...\n')
			metarcontent=urlread('http://weather.uwyo.edu/cgi-bin/wyowx.fcgi?TYPE=sflist&DATE=current&HOUR=current&UNITS=A&STATION=ZGGG');
		catch
			return;		
		end	
		start=strfind(metarcontent,'<PRE>');
		metarcontent=metarcontent(start:length(metarcontent));	%cut out '<pre>' to </pre>
		fid1=fopen('parameter/metar.txt','w');
		fprintf(fid1,'%s',metarcontent);
		fclose(fid1);	
		[bca,qflag]=metars();
	end



function [metarca,q]=metars()
%METARS: Caculate the background cloud cover by the latest metar from ZGGG
%	INPUT:
%	OUTPUT:
%		bkca:	background cloud cover by the latest metar from ZGGG 
%	EXAMPLE:
%		bkca=assimilation()

%LOG:
%2013-01-23:	Completed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	global c;
	q=1;	% satisfy to request METAR		
	metarca=-1;
	skycondition=0;
	flag=0;	%flag that successfully get 1 or more metar
	readtime=0;

	fid1=fopen('parameter/metar.txt','r');
	try
		line=fgetl(fid1);
		line=fgetl(fid1);
		clouds=strfind(line,'CLOUDS');
		if(length(clouds))
			for j=3:4	%process the headline
				line=fgetl(fid1);
			end	
		else
			metarca=0;
			return;
		end
	catch
		metarca=-1;
		return;
	end
	while((~(feof(fid1)))&(readtime<6))
		line=fgetl(fid1);
		readtime=readtime+1;
		metarday=str2num(line(6:7));
		metarhour=str2num(line(9:10))+8;
		metarmin=str2num(line(11:12));
		if metarhour>23
			metarday=metarday+1;
			metarhour=metarhour-24;		
		end

		if (metarday==c(3))&((abs(((metarhour*60+metarmin)-(c(4)*60+c(5))))<=45))
			q=0;	%the latest metar is less than 30min from now	
		end
		if length(line)>12
			if (metarday==c(3))&((abs(((metarhour*60+metarmin)-(c(4)*60+c(5))))<=60))
				flag=flag+1;
				%be sure the first one is the true skycondition
				len=0;
				
				ovc=[];
				bkn=[];
				sct=[];
				few=[];
				clr=[];
				
				
				ovc=strfind(line,'OVC');
				bkn=strfind(line,'BKN');
				sct=strfind(line,'SCT');
				few=strfind(line,'FEW');
				clr=strfind(line,'CLR');
				if(length(ovc))
					skycondition=skycondition+1;
				elseif(length(bkn))
					skycondition=skycondition+0.8;
				elseif(length(clr))
					skycondition=skycondition+0;
				else
					if(length(sct))
						len=len+length(sct);
						skycondition=skycondition+0.4375*(1-0.5^len)*2;
					end
					if(length(few))
						len=len+length(few);
						skycondition=skycondition+(0.1875*(0.5^(len-1)))*(1-0.5^length(few))*2;
					end
				end
			end
		end
	end
	if(flag>0)
		skycondition=skycondition/flag;
	else
		skycondition=-1;
	end
	fclose(fid1);
	metarca=skycondition;
