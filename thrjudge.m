%------------------------------Function THRJUDGE()------------------------------
function thrcc=thrjudge(im,dnflag,fn)
%THRJUDGE: CRUCIAL FUNCTION. Judge the cloud or sky area with threshold
%	INPUT:
%		im:	the processed img
%		fn:	the processed img filename
%		dnflag:	day or night time flag 0 for day and 1 for night	
%		cc0:	the cloud-cover judged by experience method
%	OUTPUT:
%		ca:	the cloud area (px) that summed up
%		sa:	the sky area (px) that summed up
%		cc:	the cloud cover computed by 12 zones
%	SUBFUNCION:
%		READFILE:	Read the parameter files
%		COARSEMESH:	Caculate the theshold in Coarse Mesh(10*10 px)
%		SMOOTH:		Smooth the theshold in Coarse Mesh (mean 9 neighbourhood)
%		BILINEARITY:	Refine the theshold in every px with Bilinear Interpolation
%		BLACKORWHITE:	Divide the picture in to logical pic
%		CLEARFRAGMENT:	Clear the fragment whose area less than 100 px
%		CLOUDCOUNT:	Sum up the Cloud Area with weighted parameters
%		TESTCLEAR:	Exam whether the clear sky judged by experience is valid
%	EXAMPLE:
%		[ca,sa,cc,cc0]=expjudge(im,fn,dnflag,cc0)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%2012-10-04:	Add dnflag
%2012-10-12:	Add TESTCLEAR module
%2013-01-22:	Modify the Algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	global standard;
	
	le=zeros(98);
	ple=zeros(98);
	acle=zeros(486);
	aves=zeros(245,4,2);
	

	
	

	[le,aves]=coarsemesh(im);
	
	ple=smooth(le);

	acle=bilinearity(ple);

	im=blackorwhite(im,acle);

	im=clearfragment(im);

	im=imcomplement(im);

	im=clearfragment(im);	

	thrcc=cloudcount(im,standard,fn);				


%------------------------------Function THEJUDGE-->COARSEMESH()------------------------------
function [le,aves]=coarsemesh(im)
%COARSEMESH: Caculate the theshold in Coarse Mesh(10*10 px)
%	INPUT:
%		im:	the processed img
%		dN:	heshold in the N quadrant(N for I\II\III and IV)
%	OUTPUT:
%		le:	the Matrix of theshold with 'dN' or Otsu Method 
%	EXAMPLE:
%		le=coarsemesh(im,d1,d2,d3,d4)

%LOG:
%2012-08-14:	Complete
%2012-10-02:	Modify the using theshold of Otsu Method to 7
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	[m,n]=size(im);							%Get the size of the pic

	cle=zeros(49);	
	le=zeros(98);
	aves=zeros(245,4,2);

	for x=1:489										
		for y=1:489
			r=(round(sqrt((x-245)^2+(y-245)^2)));	
			if(r<240)&(r>0)
				if(x<=244)&(y>=245)			%I and Y+
					q=1;
				elseif(x<=245)&(y<=244)			%II and X-
					q=2;
				elseif(x>=246)&(y<=245)			%III and Y-
					q=3;
				elseif(x>=245)&(y>=246)			%IV and X+
					q=4;
				end
				aves(r,q,1)=aves(r,q,1)+double(im(x,y));
				aves(r,q,2)=aves(r,q,2)+1;
			end
		end
	end
	aves(:,:,1)=aves(:,:,1)./aves(:,:,2);
	for i=1:49
		for j=1:49
			x=10*(i-1)+5;
			y=10*(j-1)+5;
			r=(round(sqrt((x-245)^2+(y-245)^2)));	%Get the distance from (i,j) to Center Point (245,245)  
			if(r<240)&(r>3)
				if(x<=244)&(y>=245)			%I and Y+
					q=1;
				elseif(x<=245)&(y<=244)			%II and X-
					q=2;
				elseif(x>=246)&(y<=245)			%III and Y-
					q=3;
				elseif(x>=245)&(y>=246)			%IV and X+
					q=4;
				end
			end
			ma=max(max(im(x-4:x+5,y-4:y+5)));
			mi=min(min(im(x-4:x+5,y-4:y+5)));
			me=mean2(im(x-4:x+5,y-4:y+5));
			if((me-mi)>7)|(r>240)
				cle(i,j) = graythresh(im(x-4:x+5,y-4:y+5));
			else
				try
					cle(i,j) = graythresh(im(x-14:x+15,y-14:y+15));
				catch
					try
						cle(i,j)=(1/16)*aves(r-2,q,1)+(1/4)*aves(r-1,q,1)+(3/16)*aves(r,q,1)+(1/4)*aves(r+1,q,1)+(1/16)*aves(r+2,q,1);
					catch
						cle(i,j)=aves(1,q,1);
					end
				end
			end
			le(2*i,2*j)=cle(i,j);
			le(2*i-1,2*j)=cle(i,j);
			le(2*i,2*j-1)=cle(i,j);
			le(2*i-1,2*j-1)=cle(i,j);
		end
	end

%------------------------------Function THEJUDGE-->SMOOTH()------------------------------
function ple=smooth(le)
%SMOOTH: Smooth the theshold in Coarse Mesh (mean 9 neighbourhood)
%	INPUT:
%		le:	the Matrix of theshold with 'dN' or Otsu Method 
%	OUTPUT:
%		ple:	the Matrix of theshold after smooth
%	EXAMPLE:
%		ple=smooth(le)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	for i=1:98
		for j=1:98
			if(i==1)&(j==1)
				ple(i,j)=(le(i,j)+le(i+1,j)+le(i,j+1)+le(i+1,j+1))/4;
				continue;
			end
			if(i==1)&(j==98)
				ple(i,j)=(le(i,j)+le(i+1,j)+le(i,j-1)+le(i+1,j-1))/4;
				continue;
			end
			if(i==98)&(j==1)
				ple(i,j)=(le(i,j)+le(i,j+1)+le(i-1,j)+le(i-1,j+1))/4;
				continue;
			end
			if(i==98)&(j==98)
				ple(i,j)=(le(i,j)+le(i,j-1)+le(i-1,j)+le(i-1,j-1))/4;
				continue;
			end
			if(i==1)&(j>1)&(j<98)
				ple(i,j)=(le(i,j)+le(i+1,j)+le(i,j-1)+le(i+1,j-1)+le(i,j+1)+le(i+1,j+1))/6;
				continue;
			end
			if(j==1)&(i>1)&(i<98)
				ple(i,j)=(le(i,j)+le(i,j+1)+le(i-1,j)+le(i-1,j+1)+le(i+1,j)+le(i+1,j+1))/6;
				continue;
			end
			if(i==98)&(j>1)&(j<98)
				ple(i,j)=(le(i,j)+le(i-1,j)+le(i,j-1)+le(i-1,j-1)+le(i,j+1)+le(i-1,j+1))/6;
				continue;
			end
			if(j==98)&(i>1)&(i<98)
				ple(i,j)=(le(i,j)+le(i,j-1)+le(i-1,j)+le(i-1,j-1)+le(i+1,j)+le(i+1,j-1))/6;
				continue;
			end
			ple(i,j)=(le(i,j)+le(i,j-1)+le(i-1,j)+le(i-1,j-1)+le(i+1,j)+le(i+1,j-1)+le(i-1,j-1)+le(i,j-1)+le(i+1,j-1))/9;
		end
	end

%------------------------------Function THEJUDGE-->BILINEARITY()------------------------------
function acle=bilinearity(ple)
%BILINEARITY: Refine the theshold in every px with Bilinear Interpolation
%	INPUT:
%		ple:	the Matrix of theshold after smooth
%	OUTPUT:
%		acle:	the accurate theshold reflect to every px in the pic 	
%	EXAMPLE:
%		acle=bilinearity(ple)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	d1=0;
	d2=0;

	for i=1:485
		for j=1:485
			if(mod(i,5)==1)&(mod(j,5)==1)
				acle(i,j)=ple(fix((i-1)/5)+1,fix((j-1)/5)+1);
			elseif(mod(i,5)~=1)&(mod(j,5)~=1)
				d1=(((fix((i-1)/5)+1)*5+1-i)/5)*ple(fix((i-1)/5)+1,fix((j-1)/5)+1)+((i-fix((i-1)/5)*5-1)/5)*ple(fix((i-1)/5)+2,fix((j-1)/5)+1);
				d2=(((fix((i-1)/5)+1)*5+1-i)/5)*ple(fix((i-1)/5)+1,fix((j-1)/5)+2)+((i-fix((i-1)/5)*5-1)/5)*ple(fix((i-1)/5)+2,fix((j-1)/5)+2);
				acle(i,j)=(((fix((j-1)/5)+1)*5+1-j)/5)*d1+((j-fix((j-1)/5)*5-1)/5)*d2;
			elseif(mod(i,5)~=1)
				acle(i,j)=(((fix((i-1)/5)+1)*5+1-i)/5)*ple(fix((i-1)/5)+1,fix((j-1)/5)+1)+((i-fix((i-1)/5)*5-1)/5)*ple(fix((i-1)/5)+2,fix((j-1)/5)+1);
			else
				acle(i,j)=(((fix((j-1)/5)+1)*5+1-j)/5)*ple(fix((i-1)/5)+1,fix((j-1)/5)+1)+((j-fix((j-1)/5)*5-1)/5)*ple(fix((i-1)/5)+1,fix((j-1)/5)+2);
			end
		end
	end

%------------------------------Function THEJUDGE-->BLACKORWHITE()------------------------------
function im=blackorwhite(im0,acle)
%BLACKORWHITE: Divide the picture in to logical pic
%	INPUT:
%		im0:	the picture that need to be divided
%		acle:	the accurate theshold in every px
%	OUTPUT:
%		im:	the picture that in black and white(with gray level in 0/255)
%	EXAMPLE:
%		m=blackorwhite(im0,acle)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

	for i=1:485
		for j=1:485
			r=(round(sqrt((i-245)^2+(j-245)^2)));	
			if(r<240)&(r>0)
				if(i<=244)&(j>=245)			%I and Y+
					q=1;
				elseif(i<=245)&(j<=244)			%II and X-
					q=2;
				elseif(i>=246)&(j<=245)			%III and Y-
					q=3;
				elseif(i>=245)&(j>=246)			%IV and X+
					q=4;
				end
				if(im0(i,j)<acle(i,j)*255)
					im(i,j)=0;
				else
					im(i,j)=255;
				end

			elseif(r>240)&(r<245) 
				im(i,j)=255;
			else
				im(i,j)=0;
			end
		end
	end
	im=im2bw(im,128/255);	
%------------------------------Function THEJUDGE-->CLEARFRAGMENT()------------------------------
function im=clearfragment(im0)
%CLEARFRAGMENT: Clear the fragment whose area less than 100 px
%	INPUT:
%		im0:	the picture that need to be clear fragment
%	OUTPUT:
%		im:	the picture that cleared the fragment
%	EXAMPLE:
%		im=clearfragment(im0)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	
	Liec=bwlabel(im0);						%Transform the 0-1pic into label pic
	stats=regionprops(Liec,'Area');					%Get every label's area
	idx=find([stats.Area]>300);					%Find the area of label that > 100
	im=ismember(Liec,idx);						%Delete the labels which area <=100	
	
	
%------------------------------Function THEJUDGE-->CLOUDCOUNT()------------------------------
function cc=cloudcount(im,standard,fn)
%CLOUDCOUNT:Sum up the Cloud Area with weighted parameters
%	INPUT:
%		im:	the picture that need to be count
%	OUTPUT:
%		cc:	cloud cover computed by 12 zones
%		ca:	the cloud area(px)
%		sa:	the sky area(px)
%	EXAMPLE:
%		[cc,ca,sa]=cloudcount(im)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%2012-10-04:	Modify the algorithm to fit eye observation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	
	cele=zeros(4,3);						%Create a Matrix that save 3 Zone Weighted Cloud in 4 quarant 
	zone=zeros(4,3);

	ca=0;								%Cloud area(px)
	sa=0;								%Sky area(px)
	
	%Another scan, in order to sum up the weighted cloud area
	
	for i=1:485
		for j=1:485
			n=0;						%Variable that define zone I II or III in every quadrant
			m=0;						%Variable that define Quadrant I II III or IV
			r=(round(sqrt((i-245)^2+(j-245)^2)));

			if(r<=200)&(r>0)

				if(r>150)
					n=3;
				elseif(r>80)
					n=2;
				else
					n=1;				
				end

				if(i<=244)&(j>=245)		%I and Y+
					m=1;
				elseif(i<=245)&(j<=244)		%II and X-
					m=2;
				elseif(i>=246)&(j<=245)		%III and Y-
					m=3;
				elseif(i>=245)&(j>=246)		%IV and X+
					m=4;
				end
				
				zone(m,n)=zone(m,n)+standard(r);				
				
				if(im(i,j)==1)
					cele(m,n)=cele(m,n)+standard(r);
					ca=ca+1;
				else
					sa=sa+1;				
				end
			end
			if (r>=200)&(r<=205)
				im(i,j)=0;
			elseif(r>205)
				im(i,j)=1;		
			end
		end
	end
	for m=1:4
		for n=1:3
			cele(m,n)=cele(m,n)/zone(m,n);		
			if(cele(m,n)>0.5)			%associated to human eyes
				cele(m,n)=1;			
			end
		end
	end 	
	cc=sum(sum(cele))/12;
	
	%kick out edge effect
	if(cc-(sum(cele(:,3))/12)<0.05)
		cc=0;
	end
	
	loc=['data/divpic/',fn(6:13),'/div_',fn(6:17),'.png'];
	if(mod(str2num(fn(16:17)),10)==0)
		imwrite(im,loc);					%Write the div pic
	end
	imwrite(im,'data/div.png');

%------------------------------Function THEJUDGE-->TESTCLEAR()------------------------------
function cf=testclear(im)
%CLOUDCOUNT:exam whether the clear sky judged by experience is valid
%	INPUT:
%		im:	the picture that divided by threshold	
%	OUTPUT:
%		cf:	the clear flag with 1 for clear and 0 for not clear
%	EXAMPLE:
%		cf=cloudcount(im)

%LOG:
%2012-10-12:	Complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

	cf=0;
	return;

	%{imo=imread('data/div.png');
	difim=xor(imo,im);					%the different area in div pic  
	[cc,ca,sa]=cloudcount(difim);				%count if invasive cloud/sky > 1 in 10 cover
	ch_sky=ca/(ca+sa);
	if (ch_sky<0.15)
		cf=1;	
	else
		cf=0;
	end%}
