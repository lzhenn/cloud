%------------------------------Function OUT_PUT()------------------------------
function delay=out_put(fn,cc,bkcc,srt,sst,mrt,mst)
%OUT_PUT:Output the divided result both in screen and files 
%	INPUT:
%		fn:	filename of the img
%		cc:	weighted cloud area
%		ca:	cloud area (px)
%		sa:	sky area (px)
%		flag:	the sign whether divided by experience
%		cc0:	the experience method divided result
%		m0:	the mean of Crucial Area
%		var:	the variance of Crucial Area
%		srt:	sunrise time
%		sst:	sunset time
%		mrt:	moonrise time
%		mst:	moonset time
%	OUTPUT:
%		delay:	the delay time of next judgement
%	EXAMPLE:
%		delay=output(fn,cc,sa,ca,flag,cc0,m0,var,srt,sst,mrt,mst)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%2012-10-03:	Modify the output with sunrise time and sunset time
%2012-10-05:	Modify the output with moonrise time and moonset time
%2012-10-25:	Add smooth module
%2013-05-26:	Update to Version.2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	
	global c;

%----------SMOOTH Cloud_Cover Record----------
	fidl=fopen('data/cloud_tiny.txt','r');
	line=fgetl(fidl);
	cclast=str2num(line(7:12));
	fclose(fidl);

	if(abs(cc-cclast)>0.2)
		cc=(cc+cclast)/2;				%Smooth cloud cover record
	end

	now_s=c(4)*3600+c(5)*60+c(6);					%Get the seconds now to midnight
	



	protime=toc;	
	delay=60-protime;						%Delay for the next execution 

	fid=fopen(['data/timeseries/',fn(6:13),'.txt'],'a');
	
	fprintf(fid,[fn(6:19),'%8.4f%6.2f\n'],cc,bkcc);
	
	fclose(fid);
	
	try			%FIX BUG: Different Day Jump
		drawpic(c(1),c(2),c(3),now_s,srt,sst,fn);
	catch
	
	end
				
	fid=fopen('data/cloud_tiny.txt','w');				%Make tiny data in order to release the stress of sever :-)		
	
	fprintf(fid,[fn(14:15),'|',fn(16:17),'|%6.4f'],cc);

	fclose(fid);

	fprintf(['\n\tCompute_Completed_Time:\t\t',datestr(now),'\n']);
	fprintf('\tCompute_Spend_Time:\t\t%3.2fs\n',protime);
	fprintf(['\tComputed_Object:\t\t',fn,'\n']);

	switch round(cc*10)						%Judge the state of the sky
		case{0}
			sky='CLEAR';
		case{1,2,3}
			sky='PARTLY CLOUDY';
		case{4,5,6,7}
			sky='CLOUDY';
		case{8,9,10}
			sky='OVERCAST SKY';
	end
	fprintf('\tCloud_Cover_Decimals:\t\t%6.4f\n',cc);
	fprintf('\tCloud_Cover_10DIV:\t\t%d\n',round(cc*10));
	fprintf('\tCloud_Cover_8DIV:\t\t%d\n\n\n',round(cc*8));
	fprintf(['\tSky_State:\t\t\t',sky,'\n']);
	fprintf('\tToday_Sunrise_Time:\t\t%s\n',srt);
	fprintf('\tToday_Sunset_Time:\t\t%s\n',sst);
	fprintf('\tToday_Moonrise_Time:\t\t%s\n',mrt);
	fprintf('\tToday_Moonset_Time:\t\t%s\n\n\n',mst);
	fprintf('SYSTEM  >>  The program is waiting for the next computing...%d s from now\n',round(delay));

%--------------------------Function DAWNDUSK()-->DRAWPIC()--------------------------
function drawpic(y,m,d,now_s,srt,sst,fn)
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
	minute=fix(now_s/60);
	cloud_rank(1440)=NaN;
	cloud_rank(:)=-1;

	ceil_rank(1440)=NaN;
	ceil_rank(:)=-1;

	srminute=str2num(srt(1:2))*60+str2num(srt(4:5));
	ssminute=str2num(sst(1:2))*60+str2num(sst(4:5));

	s=['data/timeseries/',int2str(y),full(m),full(d),'.txt'];
	fid=fopen(s,'r');
	while(feof(fid)==0)
		caline=fgetl(fid);
		rmin=str2num(caline(9:10))*60+str2num(caline(11:12))+1;
		cloud_rank(rmin)=str2num(caline(16:21));
		try
			ceil_rank(rmin)=str2num(caline(24:28));	
		catch
		end	
	end	
	fclose(fid);
	
	for i =2:1439
		if (cloud_rank(i)==-1)
			if (cloud_rank(i-1)~=-1)&(cloud_rank(i+1)~=-1)		
				cloud_rank(i)=cloud_rank(i-1);
			else
				cloud_rank(i)=NaN;		
			end		
		end
		if (ceil_rank(i)==-1)
			if (ceil_rank(i-1)~=-1)&(ceil_rank(i+1)~=-1)		
				ceil_rank(i)=ceil_rank(i-1);
			else
				ceil_rank(i)=NaN;		
			end		
		end	
	end
	
	font_size=16;
	figure('Visible','off');
	plot(cloud_rank*10,'-b','LineWidth',1.1);
	hold on;
	plot(ceil_rank*10,'-r');

	%	Legend position
	% 1----right top
	% 2----left top
	% 3----left bottom
	% 4----right bottom

	legend_pos =1;	%right top
	if (rmin>720)
		if mean(cloud_rank(1:600))<0.5
			legend_pos = 2;
		else		
			legend_pos = 3;
		end	
	end	


	legend('Image derived cloud amount','Ceilometer hit ratio in the last 30min',legend_pos);

	%realtime point
	plot(rmin,ceil_rank(rmin)*10,'>','MarkerEdgeColor','b','MarkerFaceColor','y','MarkerSize',6);
	plot(rmin,cloud_rank(rmin)*10,'>','MarkerEdgeColor','b','MarkerFaceColor','g','MarkerSize',7);

	%sunrise and sunset
	plot(srminute-120:srminute+120,cloud_rank(srminute-120:srminute+120)*10,'-','Color',[0.5 0.5 0.5],'LineWidth',1.1);
	plot(ssminute-120:ssminute+120,cloud_rank(ssminute-120:ssminute+120)*10,'-','Color',[0.5 0.5 0.5],'LineWidth',1.1);
	axis([0 1440 -0.05 10.05]);
	set(gca,'xtick',1:60:1441,'xticklabel',(0:60:1441)/60);
	ylabel('Cloud Cover in 10Div Mode');
	xlabel('Hour');
	title(['Cloud Cover TimeSeries ( Current Cloud Amount: ',num2str(round(cloud_rank(rmin)*100)/10),'/10 @ ',fn(14:15),':',fn(16:17),' ',int2str(y),'/',full(m),'/',full(d),')']);
	set(get(gca,'XLabel'),'FontSize',font_size);
	set(get(gca,'YLabel'),'FontSize',font_size);
	set(get(gca,'title'),'FontSize',14);
 	
	%line([srminute-120 srminute-120],[0 10],'LineStyle','--','Color',[1 0.5 0],'LineWidth',1);
	line([srminute srminute],[0 10],'LineStyle','--','Color','y','LineWidth',2);
	text(srminute-45,0.2,'Sunrise')
	%line([srminute+120 srminute+120],[0 10],'LineStyle','--','Color',[1 0.5 0],'LineWidth',1);
	
	%line([ssminute-120 ssminute-120],[0 10],'LineStyle','--','Color',[1 0.5 0],'LineWidth',1);
	line([ssminute ssminute],[0 10],'LineStyle','--','Color','y','LineWidth',2);
	text(ssminute-45,0.2,'Sunset')
	%line([ssminute+120 ssminute+120],[0 10],'LineStyle','--','Color',[1 0.5 0],'LineWidth',1);

	saveas(gcf,'data/time_series.png','png');
	%saveas(gcf,'../../www/html/time_series.png','png');
	close(gcf);

%---------------------Function DAWNDUSK-->DRAWPIC-->FULL()---------------------
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


