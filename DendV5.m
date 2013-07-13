function [  ] = DendV5()
%DENDV Render a dendrite's electrical properties
%   DendV visualizes the various current flow within a dendrite compartment
%   Including: Axonal, NMDA, K+, Na+, Leak, Transmembrane

%   DendV was  built using OpenGl + MATLAB
%   For any issues or questions, please contact Andrew Schreiber at
%   aschreib@usc.edu
%   USC Lab for Neural Computation

%{
TO DO:
-unit/scale key
-Function to determine # of bars
-Utilize number of compartments = size(d)
-Record as video
-Set loading screen as intro
%}





%{
function Display_Press(~,event)
    if event.Character == 's'
        figure(1);
        plot(sodium');
        title('Sodium vs Time');
    end
    if event.Character == 'p'
        figure(1);
        plot(potass');
        title('Potassium vs Time');
    end
    if event.Character == 'n'
        figure(1);
        plot(nmda');
        title('NMDA vs Time');
    end
    if event.Character == 'a'
        figure(1);
        plot(ampa');
        title('AMPA vs Time');
    end
    if event.Character == 'x'
        figure(1);
        plot(axial');
        title('Axial vs Time');
    end
    if event.Character == 'v'
        figure(1);
        plot(volt');
        title('Millivolts vs Time');
    end
    if event.Character == 'q'
        continued=false;
    end
    if event.Character == '-'
        steps=steps-1;
    end
    if event.Character == '='
        steps=steps+1;
    end
    if event.Character ==' '
        if pauser==1
            pauser=0;
        else
            pauser=1;
        end
    end
       set(0,'CurrentFigure', figure(3));
end
%}

pause on;
close all;
scrsz = get(0,'ScreenSize');

%Figure 1 - Axial/Diameter/Volt - Middle


startbarsize=45;

figure('Position', [0 startbarsize scrsz(3) scrsz(4)*.92],...
    'Toolbar', 'none');
set(gcf,'Units','normal')
set(gca,'Position',[0 0 1 1])
text(.46,.5,'Loading...', 'FontSize', 25);


%Get Variables from file
%BardiaSimulation.mat
%onetrace.mat

Datafile= load('BardiaSimulation.mat');

global sodium;
global potass;
global nmda;
global ampa;
global axial;
global volt;
global distance;
global pauser;
global diam;
global cap;
global pas;

sodium = Datafile.ina;
potass = Datafile.ik;
nmda = Datafile.inmda;
ampa = Datafile.iampa;
axial = Datafile.iaxial;
volt = Datafile.v;
distance = Datafile.d; %distance from soma in microns
diam = Datafile.diam; %microns
cap= Datafile.icap;
pas= Datafile.ipas;

%Absolute values of data points. Non-zero.
AbsNa = -1*(sodium-eps);
AbsK = potass+eps;
AbsAMPA = -1*(ampa -eps);
AbsNMDA = -1*(nmda -eps);
AbsV = abs(volt+eps);
AbsAxial = abs(axial+eps);
AbsCap= abs(cap +eps);
AbsPas=abs(pas+eps);


set(0,'CurrentFigure',figure(1) );

%General Settings
[~,maxtime]=size(ampa);
[maxcompart,~]=size(potass);
continued=true;
steps=1;                     %Temporal jump per loop
Time=980;                   %Start time
pauser=0;                    %Set to 1 to disable bar chart, 0 to enable
LegendSpace=.10;
LegendStart=1-LegendSpace;
SpaceConstant=1/maxcompart *(LegendStart);  %Width of one compartment
Cushion=.025;



%Box chart settings
DifftoZero=min(ceil(volt(:)));                     %Takes smallest value in volt
VoltRange= abs( max(ceil(volt(:))) - DifftoZero);  %Range of Volt; works {++,+-,-+,--}
boxcolormap=colormap(jet(VoltRange));              %Sets range-based Jet colormap
AxialScaler=(.9*SpaceConstant)/max(abs(axial(:))); %Multiplies with axial current to fit in compartment
LineY2=.505;                                       %Midpoint of Box chart
BoxScaler=1/max(diam) * (.33 - 2*Cushion);           %*(.33) for scale to 1/3 of figure
BoxMaxLine=LineY2+ .165- Cushion;
BoxMinLine=LineY2- .165+ Cushion;


%Bar chart settings
BaseLineX1=.1*SpaceConstant;            %Adjust space between midlines
BaseLineX2=BaseLineX1+SpaceConstant*.8; %Adjust .1 or .8 to adjust space from left and right, respectively
BarWidth=SpaceConstant*.8/6;            %6 bars currently **replace with a GetBars
BarMult=2.5;                            %Manual scalar for barsize
LineY1=.835;                            %Midline location
MaxBar=.165 - Cushion;                  %Maximum allowed size for bar
BarMaxLine= LineY1 + .165 - Cushion;
BarMinLine= LineY1 - .165 + Cushion;


%Line chart settings
VoltScaler=(1/max(abs(volt(:)))) * (.165 - Cushion);    %Set * (.165) so maxline is within boundaries and cushion
LineChartMidY= .165;
LineMaxLine=LineChartMidY +.165 - Cushion;
LineMinLine=LineChartMidY -.165 + Cushion;

clf;

str3 =['STEP: ', num2str(steps/10), 'ms'];
StepDisplay=annotation('textbox', [.8 .97 .07 .03],...
                       'String', str3,...
                       'LineStyle', 'none'); %position [fromleft frombottom width height]
str2=['TIME: ', num2str(Time/10),'ms'];
TimeDisplay=annotation('textbox', [.7 .97 .07 .03],...
                       'String', str2,...
                       'LineStyle', 'none');


%Spacing for arrows
LineX1 =BaseLineX1;
LineX2 =BaseLineX2;
BarX=BaseLineX1;
SodiumX=1:1:maxcompart;
PotassiumX=1:1:maxcompart;
AMPAX=1:1:maxcompart;
NMDAX=1:1:maxcompart;
CapX=1:1:maxcompart;
PasX=1:1:maxcompart;

%Legend display
annotation('line', [(LegendStart) (LegendStart)], [BarMaxLine BarMinLine]);
annotation('line', [(LegendStart) (LegendStart)], [BoxMaxLine BoxMinLine]);
annotation('line', [(LegendStart) (LegendStart)], [LineMaxLine LineMinLine]);


annotation('line', [0 LegendStart], [BarMaxLine BarMaxLine]);
BarMaxStr=[num2str(steps/10), 'ms'];
annotation('textbox',[LegendStart, BarMaxLine-.5*Cushion, .05, .05],... %-.5*Cushion for ideal alignment
           'String', BarMaxStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');

annotation('line', [0 LegendStart], [BarMinLine BarMinLine]);
BarMinStr=[num2str(steps/10), 'ms']; 
annotation('textbox',[LegendStart, BarMinLine-.5*Cushion, .05, .05],...
           'String', BarMinStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

       
annotation('line', [0 LegendStart], [BoxMaxLine BoxMaxLine]);
BoxMaxStr=[num2str(steps/10), 'ms']; 
annotation('textbox',[LegendStart, BoxMaxLine-.5*Cushion, .05, .05],...
           'String', BoxMaxStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

annotation('line', [0 LegendStart], [BoxMinLine BoxMinLine]);
BoxMinStr=[num2str(steps/10), 'ms']; 
annotation('textbox',[LegendStart, BoxMinLine-.5*Cushion, .05, .05],...
           'String', BoxMinStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 


annotation('line', [0 LegendStart], [LineMaxLine LineMaxLine]);
LineMaxStr=[num2str(steps/10), 'ms']; 
annotation('textbox',[LegendStart, LineMaxLine-.5*Cushion, .05, .05],...
           'String', LineMaxStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

annotation('line', [0 LegendStart], [LineMinLine LineMinLine]);
LineMinStr=[num2str(steps/10), 'ms']; 
annotation('textbox',[LegendStart, LineMinLine-.5*Cushion, .05, .05],...
           'String', LineMinStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 


       
annotation('line', [0 LegendStart], [LineChartMidY LineChartMidY],...
           'LineStyle', '--'); 



%Setting up display
for arrowloop=1:maxcompart
BoxX(arrowloop)=SpaceConstant*arrowloop-SpaceConstant;
end

for arrowloop=1:maxcompart
    if continued==false
        break;
    end
    
    
    %Midlines
    annotation('line', [LineX1 LineX2], [LineY1 LineY1]);
    
    %Sodium
    SodiumBarSize=min(MaxBar, BarMult*AbsNa(arrowloop, Time));
    SodiumBar(arrowloop)=annotation('rectangle', ... #x, y, width, height
        [BarX LineY1-SodiumBarSize BarWidth SodiumBarSize],...
        'FaceColor',[1 0 0],... %R G B
        'LineWidth', .0005);
    SodiumX(arrowloop)= BarX;
    BarX=BarX+BarWidth;    %Set next bar
    
    %Potassium current
    PotassiumBarSize=min(MaxBar, BarMult*AbsK(arrowloop, Time));
    PotassiumBar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-.0005 BarWidth PotassiumBarSize],...
        'FaceColor',[1 .9 0],...    
        'LineWidth', .0005);
    PotassiumX(arrowloop)= BarX;
    BarX=BarX+BarWidth;
    
    
    %AMPA current
    
    AMPABarSize=min(MaxBar, BarMult*AbsAMPA(arrowloop, Time));
    AMPABar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-AMPABarSize BarWidth  AMPABarSize],...
        'FaceColor',[1 0 1],...
        'LineWidth', .0005);
    
    AMPAX(arrowloop)= BarX;
    BarX=BarX+BarWidth;
    
    %NMDA current
    
    
    NMDABarSize=min(MaxBar, BarMult*AbsNMDA(arrowloop, Time));
    NMDABar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-NMDABarSize BarWidth NMDABarSize],...
        'FaceColor',[.5 .5 .1],...
        'LineWidth', .0005);
    
    NMDAX(arrowloop)= BarX;
    BarX= BarX + BarWidth;
    
    
    %Capacitive current
    CapBarSize=min(MaxBar, BarMult*AbsCap(arrowloop, Time));
    if cap(arrowloop, Time)>0
        
        CapBar(arrowloop)=annotation('rectangle',...
            [BarX LineY1-.0005 BarWidth CapBarSize],...
            'FaceColor',[0 1 0],...
            'LineWidth', .0005);
        
    else
        CapBar(arrowloop)=annotation('rectangle',...
            [BarX LineY1-CapBarSize BarWidth CapBarSize],...
            'FaceColor',[0 1 0],...
            'LineWidth', .0005);
    end
    CapX(arrowloop)= BarX;
    BarX= BarX + BarWidth;
    
    %Passive current here
    PasBarSize=min(MaxBar, BarMult*AbsPas(arrowloop, Time));
    PasBar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-.0005 BarWidth PasBarSize],...
        'FaceColor',[0 0 1],...
        'LineWidth', .0005);
    PasX(arrowloop)=BarX;
    
    
    %Move to next compartment

    
    
 %Box Chart
    BoxSize=BoxScaler*diam(arrowloop);          %Scales current value to range of rendering
    BoxFromBot=LineY2-.5*BoxSize;               %Determines lowest point of box; subtracts half box size from midline
    
    ColorNumber=ceil(volt(arrowloop,Time))+abs(DifftoZero);
    BarColor=[boxcolormap(ColorNumber,1) boxcolormap(ColorNumber,2) boxcolormap(ColorNumber,3)];
    
    DiamBar(arrowloop)=annotation('rectangle',[BoxX(arrowloop) BoxFromBot SpaceConstant BoxSize],...
        'FaceColor', BarColor); %fromleft frombottom width height
    
    
    %Axial current
    AxialBarSize=AxialScaler*axial(arrowloop,Time);
    AxialX2=max(.000001,min(.99, -1*AxialBarSize)); % *-1 to correct axial directions

    AxialBar(arrowloop)=annotation('rectangle',...
        [BoxX(arrowloop) .49 AxialX2 .02],...
        'FaceColor',[.5 .1 .1],...
        'LineWidth', .0005);
    
    
    
    
    
 %Line Chart
    VoltLine(arrowloop)=annotation('line', [BoxX(arrowloop) (BoxX(arrowloop)+SpaceConstant)], [.2 .2],...
                'Color', [.5 .2 1],...
                'LineWidth', 2);
        
    LineX1 =LineX1 + SpaceConstant;
    LineX2 =LineX2 + SpaceConstant;
    BarX=LineX1;
    
end


%-------------Main Display Loop-----------------%
while Time<maxtime && continued==true    
    
 %   set(0,'CurrentFigure',figure(1) );
    
    str3=['STEP: ',num2str(steps/10),'ms'];
    set(StepDisplay, 'String', str3);
    str3=['TIME: ',num2str(Time/10),'ms'];
    set(TimeDisplay, 'String', str3)
    
    
    for arrowloop=1:maxcompart
        
        SodiumBarSize=min(MaxBar, BarMult*AbsNa(arrowloop, Time));
        SodiumBarPos=[SodiumX(arrowloop) LineY1-SodiumBarSize BarWidth SodiumBarSize];
        set(SodiumBar(arrowloop),'Position', SodiumBarPos);
        
        PotassiumBarSize=min(MaxBar, BarMult*AbsK(arrowloop, Time));
        PotassiumBarPos=[PotassiumX(arrowloop) LineY1-.0005 BarWidth PotassiumBarSize];
        set(PotassiumBar(arrowloop),'Position', PotassiumBarPos);
        
        AMPABarSize=min(MaxBar, BarMult*AbsAMPA(arrowloop, Time));
        AMPABarPos=[AMPAX(arrowloop) LineY1-AMPABarSize BarWidth AMPABarSize];
        set(AMPABar(arrowloop),'Position', AMPABarPos);
        
        
        NMDABarSize=min(MaxBar, BarMult*AbsNMDA(arrowloop, Time));
        NMDABarPos=[NMDAX(arrowloop) LineY1-NMDABarSize BarWidth NMDABarSize];
        set(NMDABar(arrowloop),'Position', NMDABarPos);
        
        
        if cap(arrowloop, Time)>0
            
            CapBarSize=min(MaxBar, BarMult*AbsCap(arrowloop, Time));
            CapBarPos=[CapX(arrowloop) LineY1-.0005 BarWidth CapBarSize];
            set(CapBar(arrowloop),'Position', CapBarPos);
            
        else
            
            CapBarSize=min(MaxBar, BarMult*AbsCap(arrowloop, Time));
            CapBarPos=[CapX(arrowloop) LineY1-CapBarSize BarWidth CapBarSize];
            set(CapBar(arrowloop),'Position', CapBarPos);
        end
        
        PasBarSize=min(MaxBar, BarMult*AbsPas(arrowloop, Time));
        PasBarPos=[PasX(arrowloop) LineY1-.0005 BarWidth PasBarSize];
        set(PasBar(arrowloop),'Position', PasBarPos);
        
        
        %Bar Chart
        ColorNumber=ceil(volt(arrowloop,Time))+abs(DifftoZero);
        BarColor=[boxcolormap(ColorNumber,1) boxcolormap(ColorNumber,2) boxcolormap(ColorNumber,3)];
        set(DiamBar(arrowloop),'FaceColor',BarColor);

        ScaledArrowX= AxialScaler*axial(arrowloop,Time);  %Sets range to -1 to 1
        
        
        AxialX2=max(.0001,min(1, -1*ScaledArrowX)); % *-1 to correct axial directions
        
        if(axial(arrowloop,Time)>0)
            AxialBarPosition= [BoxX(arrowloop) .49 AxialX2 .02];
        else
            AxialBarPosition= [BoxX(arrowloop)-AxialX2 .49 AxialX2 .02];
        end
        set(AxialBar(arrowloop),'Position', AxialBarPosition);

        
        %Voltage Line
        VLY1=VoltScaler*volt(arrowloop,Time);
        VLY2=VoltScaler*volt(arrowloop+1,Time);
        VoltLineY= [(VLY1+LineChartMidY) (VLY2+LineChartMidY)];
        
        set(VoltLine(arrowloop),'Y', VoltLineY);
        
        

        
        
        
    end
    
    
   % set(0,'CurrentFigure',figure(1) );
    
    %MovieFrames(Time)=getframe;
    
    drawnow;
    pause(.035); %Pause between switching frames
    
    
    Time = Time + steps; %Update time loop
    
end %End main loop

%writerObj = VideoWriter('DendV5Movie');
%open(writerObj);
%writeVideo(writerObj,MovieFrames);

end %End Function



















