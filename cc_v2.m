function cc_v2()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!!MAIN FUNCTION!!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CC: MAIN FUNCTION.Read the newest '.jpg' file of CAM8,Caculate the cloud-cover and save the result in txt
%
%SUBFUNCTION LIST:
%
%	DAWNDUSK:	Judge whether now is dawn or dusk(acute light changing time) and draw timerank pic
%	READIMG:	Read the newest 'jpg' file of CAM8 and do the geometrical process
%	IMENHANCE: 	Enhance the img in order to get rid of noise
%	EXPJUDGE: 	Judge the sky condition with experience(Crucial Area's Mean and Variance)
%	THRJUDGE: 	Enhance the img in order to get rid of noise
%	-->READFILE:		Read the parameter files
%	-->COARSEMESH:		Caculate the theshold in Coarse Mesh(10*10 px)
%	-->SMOOTH:		Smooth the theshold in Coarse Mesh (mean 9 neighbourhood)
%	-->BILINEARITY:		Refine the theshold in every px with Bilinear Interpolation
%	-->BLACKORWHITE:	Divide the picture in to logical pic
%	-->CLEARFRAGMENT:	Clear the fragment whose area less than 100 px
%	-->CLOUDCOUNT:		Sum up the Cloud Area with weighted parameters
%	OUT_PUT:	Output the divided result both in screen and files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%LOG:
%2012-08-14:	Complete
%2012-09-14:	Modify the threshold method with Local-Otsu Algorithm
%2012-10-02:	Function all module in order to fit modularized programming and expanding the project
%2012-10-03:	Modify the description and comments, Add DawnDusk function, Add running time 
%2012-10-03:	Add DAWNDUSK Function to judge the acute light changing time for rest
%2012-10-04:	Draw pic of the Cloud Cover time rank of today during dawn or dusk pause
%2012-10-05:	Add moonrise and moonset time getting from HKO PDA page by getforcast.php in www/html/wap
%2012-10-12:	Add CLEARTEST module in thrjudge
%2013-05-24:	Update to Version 2.0, with assimulation and sample test
%2014-11-26:    Bug fix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



	clear all;
	close all;
	echo off;		
	path(path,'/home/eesael/wx/cloud');				%add cloud dir into search list


%---------------------------------INITIALIZATION---------------------------------
	global standard;
	global sunline;
	global c;


	cl=clock();
	
	fid1=fopen('parameter/sundata.txt','r');				
	for i=1:366
		sunline=fgetl(fid1);
		if str2num(sunline(1:2))==cl(2)&str2num(sunline(4:5))==cl(3)	%Get the right line of today
			break;		
		end
	end
	fclose(fid1);

	standard=load('parameter/standardization.txt');

%----------------------------------------------------------------------------

	lastrad=-1;						%lastrad determine the change when radcc not 1 or 0
	while 1
		%------------------------------Clear Module------------------------------
		c=clock();		
		close all;
		echo off;
		tic;			%Pressdown the timer
		

		expcc=-2;						%cloud amount based on experience, -2 for daytime
		bkca=-1;						%background cloud amount
		radcc=-1;						%cloud amount based on radiation
		expdelta=0;
		
		bflag=0;						%default: no body on the sky
		body_X=0;
		body_Y=0;
	
		
		fprintf('\n---------------------------------INFORMATION LIST---------------------------------\n\n');
		fprintf('SYSTEM  >>  Now is computing the Cloud_Cover, Please WAIT...\n\n');
		delay=0;

		[delay,srt,sst,mrt,mst,now_s,dnflag,lnflag,sunh]=dawndusk();%User's function: dawndusk()	
			
		%------------------------------Input Module------------------------------

		fprintf('        >>  Pre-treatment module...\n');									
		fn='';						%Store the newest 'jpg' file name
		try
			[fn,im]=readimg2(sunh);				%User's function: imread()
		catch
			fprintf('        >>  Error during readimg,\n        >>  system will pause 120s for another request!\n');
			pause(120);	
			continue;		
		end
		pict=fn(6:17);
		JLday=timeget(pict);
		%BUG FIX(26/09/2012):if there is any file then do the divided job
		if (size(fn)<=10)
			fprintf('        >>  Error during readimg,\n        >>  system will pause 120s for another request!\n');
			pause(120);						
			continue;			
		end				
		%------------------------------Assimilation Module------------------------------
		bkcc=assimilation();
		%---------Daytime Radiation Judgement---------
		if(dnflag)
			%imo=im;
			%[expcc,expdelta]=expjudge(fn,im,imo);
		else
			radcc=ccbyrad(sunh,pict,lastrad,bkcc);
			lastrad=radcc;
		end
		
		%------------------------Sun & Moon Process Module-------------------------
		[body_X,body_Y,bflag,bsize]=ifbodyhere(im,sunh,pict);
	

		%------------------------------Compute Module------------------------------	
		%-----------Threshold Judgement---------------
		fprintf('        >>  Threshold Judgement...\n');
		thrcc=thrjudge2(im,sunh,dnflag,fn,bflag,body_X,body_Y,radcc,bkcc,bsize);			%User's function: thrjudge()
		cc=mingle(fn,expcc,bkcc,radcc,thrcc,bflag,dnflag,sunh,expdelta);		%User's function: mingle all judgements
		%------------------------------Output Module------------------------------
		delay=out_put(fn,cc,bkcc,srt,sst,mrt,mst);	%User's function: output()		
		fprintf('        >>  If you want to stop it,\n')
		fprintf(2,'        >>  PRESS CTRL+C(UNIX/LINUX) or CTRL+PAUSE|BREAK.(Windows)\n\n')
		fprintf(2,'        >>  WARNING:NEVER STOP THIS PROGRAM AT WILL!!! \n');
		fprintf('-------------------------------------------------------------------------------------------\n\n');	
		fclose('all');	%try close unclosed files
		pause(delay);
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cc=mingle(fn,expcc,bkcc,radcc,thrcc,bflag,dnflag,sunh,expdelta)
	cc=thrcc;
	fprintf('        >>cc:%5.2f\texpcc:%5.2f\tbkcc:%5.2f\tradcc:%5.2f\tthrcc:%5.2f\n',cc,expcc,bkcc,radcc,thrcc);
	fid=fopen(['data/record/',fn(6:13),'.txt'],'a');
	fprintf(fid,[fn(6:19),'\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\n'],cc,expcc,bkcc,radcc,thrcc);
	fclose(fid);
	
function JLday=timeget(filename)
	y=str2num(filename(1:4));
	m=str2num(filename(5:6));
	d=str2num(filename(7:8));
	h=str2num(filename(9:10));
	mn=str2num(filename(11:12));
	JLday=datenum(y,m,d,h,mn,0);
