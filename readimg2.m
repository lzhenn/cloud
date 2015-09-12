%------------------------------Function READIMG()------------------------------
function [fn,im]=readimg2(sunh)
%READIMG: Read the newest 'jpg' file of CAM8 and do the geometrical process
%	INPUT:
%		NONE
%	OUTPUT:
%		im: the newest img that read from CAM8,which take up 491*491*3B in memory after geometrical process 
%		fn: the filename of the newest img, e.g. 'ch01_20121003000037.jpg'. IF FAILED,WITH RETURN 'empty' 
%	EXAMPLE:
%		[im,fn]=readim()

%LOG:
%2012-08-14:	Complete
%2012-10-02:	Modify the BUG FIX module to fit function module
%2012-10-03:	Modify the description and comments
%2012-12-08:	Rewrite the process of getting dir of ch01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	

	
		
	path0 = '../../archive/cam_src/cc_test/';		%date dir name
	im=zeros(576,704,3);
	if sunh>0
		picnum=5;
		range=240;
	else
		range=200;
		picnum=10;	
	end
	
	while 1							%keep trying reading img
		fid1=fopen([path0,'status.dat'],'r');	
		if fid1==0
			pause(5);
			continue;
		end			
		status=fgetl(fid1);
		if strcmp(status,'finished')
			timestamp=fgetl(fid1);
			for i =1:picnum					%read img
				fn=['ch01_',full(i),'.bmp'];
				try	
					im0=imread([path0,fn]);
				catch
					fprintf('SYSTEM  >>  Info:Image format ruined\n\n');	
					pause(25);
					continue;
				end				
				im=im+double(im0);	
			end
			im=im/(256*picnum);
			fclose(fid1);	
		else	
			fclose(fid1);
			pause(5);
			continue
		end
		break
	end

	
	fn=['ch01_',timestamp,'.jpg'];
	im = imresize(im, [527 704]);					%Change the size of picture
	im=im(21:510,109:598,:);					%Cut out the interesting part

	for i=1:490
		for j=1:490
			r=(round(sqrt((i-245)^2+(j-245)^2)));		
			if(r>range)
				im(i,j,:)=[0 0 0];
			end
		end
	end
	imwrite(im,'data/Before_Enhance_RGB.png');
	if(exist(['data/divpic/',fn(6:13)])==0)		%If there is no such dir,make it
		mkdir('data/divpic/',fn(6:13));	
	end

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
				
