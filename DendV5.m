function [  ] = DendV5(Filename, StartTime, EndTime)
%DENDV Render a dendrite's electrical properties
%   DendV visualizes the various current flow within a dendrite compartment
%   Including: Axonal, NMDA, K+, Na+, Leak, Transmembrane

%   DendV was built using MATLAB
%   For any issues or questions, please contact Andrew Schreiber at
%   aschreib@usc.edu or Dr. Bartlett Mel at mel@usc.edu
%   USC Lab for Neural Computation

%Todo ideas
%Tell the width of a compartment
%Scale compartment width based on distance file (hard)
%Tell which compartment is the selected compartment



%Todo%%%%%%%%%%%%%%%%%%%%%%%
%++New bar order: capacitive, passive (say instead of leak), K+ (not potassium), Na+, AMPA, NMDA. Legend to
%match

%++Distance under box chart. 2 levels. aligned left / right.

%--New model that lets you set the value at the legend and the graph works accordingly
%Round numbers on box chart size (1 and 0). take off 3. one line.
%Round number on ion channel chart (1 instead of .98). Adjust bar size
%accordingly. Same as above.


%++Axial legend pointing other direction under compartment to left of current

%++change "voltage at selected compartment" to "voltage at stimulated
%compartment"

%++Change proximal <-> distal to Dendritic Length ---->

%++Put mv on axial color legend

%++Place _currents_ above ion channel chart legend items and move other items
%there accordingly


%++Implement function to map size of ion channel / box chart to a given legend value
%++Dendrite length clipping fix
%++label input with "Synaptic Input"
%++fix clipping on from-soma
%--fix bold on 'In" -> Submitted bug report
%Record at 1 and .1 on ion channel chart


    function mapped_variable=map_compartment(variable,type)
        comp_size=maxcompart/newmaxcompart;
        rem_size= rem(comp_size,1);
        percentin=1;
        curr=0;
        
        if type==1
            compartcount=1;
            for jk=1:newmaxcompart
                while comp_size>0
                    curr= curr+ percentin*variable(compartcount,:);
                    comp_size=comp_size-percentin;
                    compartcount=compartcount+1;
                    percentin=1;
                    if comp_size<1
                        if compartcount<=maxcompart
                            curr=curr + comp_size* variable(compartcount,:);
                        end
                        percentin=1-comp_size;
                        comp_size=0;
                    end
                end
                comp_size=maxcompart/newmaxcompart;
                mapped_variable(jk,:)=curr;
                curr=0;
            end
        end
        
        if type==2
            compartcount=1;
            for jk=1:newmaxcompart
                mapped_variable(jk,:)=variable(compartcount,:);
                compartcount=int64(compartcount+comp_size-rem_size);
            end
        end
        
        if type==3
            compartcount=1;
            for jk=1:newmaxcompart
                while comp_size>0
                    curr= curr+ percentin*variable(compartcount,:);
                    comp_size=comp_size-percentin;
                    compartcount=compartcount+1;
                    percentin=1;
                    if comp_size<1
                        if compartcount<=maxcompart
                            curr=curr + comp_size* variable(compartcount,:);
                        end
                        percentin=1-comp_size;
                        comp_size=0;
                    end
                end
                comp_size=maxcompart/newmaxcompart;
                mapped_variable(jk,:)=curr/comp_size;
                curr=0;
            end
        end
        
        
    end


%Initializing
pause on;
close all;
StartTime=StartTime*10;
EndTime=EndTime*10;
scrsz = get(0,'ScreenSize');
startbarsize=45;
Filename='BardiaSimulation.mat';
Title=strcat('DendV5 -  {',Filename,'}');

%Loads matrix data file
Datafile= load(Filename);

%Main Figure Window
figure('Position', [0 startbarsize scrsz(3) scrsz(4)*.92],...
    'Toolbar', 'none',...
    'Name',Title,...
    'NumberTitle','off');
set(gcf,'Units','normal');
set(gca,'Position',[0 0 1 1]);
set(gca,'DrawMode', 'fast');
set(0,'defaultTextFontUnits', 'normalized',...
    'defaultTextFontSize', .020)
%Load Frame
text(.3,.5,'Loading...', 'FontSize', .2);



%initializing
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
global maxcompart;
global newmaxcompart;

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



set(0,'CurrentFigure',figure(1) );
[~,maxtime]=size(ampa);
[maxcompart,~]=size(potass);
LoopAdd=1; %Dont change value


MapCompartments=true;  %Map data compartments to another # of compartments
newmaxcompart=10;

if MapCompartments==true && newmaxcompart<maxcompart
    sodium=map_compartment(sodium,1);
    potass=map_compartment(potass,1);
    nmda=map_compartment(nmda,1);
    ampa=map_compartment(ampa,1);
    axial=map_compartment(axial,2);
    volt=map_compartment(volt,3);
    diam=map_compartment(diam,3);
    cap=map_compartment(cap,1);
    pas=map_compartment(pas,1);
    maxcompart=newmaxcompart;
end



%Absolute values of data points. Non-zero.
AbsNa = -1*(sodium-eps);
AbsK = potass+eps;
AbsAMPA = -1*(ampa -eps);
AbsNMDA = -1*(nmda -eps);
AbsV = abs(volt+eps);
AbsAxial = abs(axial+eps);
AbsCap= abs(cap +eps);
AbsPas=abs(pas+eps);


%General settings
continued=true;
steps=1;                       %Temporal jump per loop
CurrentTime=StartTime;                     %Start time
pauser=0;                      %Set to 1 to disable bar chart, 0 to enable
LegendSpace=.435;
LegendStart=1-LegendSpace;
SpaceConstant=1/maxcompart *(LegendStart);  %Width of one compartment
Cushion=.015;                               %Vertical space between graphs
recordmovie=true;                          %Records a video into current directory. Set true/false


%Ion Channel Graph settings
BaseLineX1=.1*SpaceConstant;            %Adjust space between bar midlines
BaseLineX2=BaseLineX1+SpaceConstant*.8; %Adjust .1 or .8 to adjust space from left and right, respectively
BarWidth=SpaceConstant*.8/6;            %6 bars currently **replace with a GetBars
BarLimit=1;                            %Manual limit for barsize
BarChartMidY=.26;                       %Midline location
MaxBar=.26 - Cushion;                   %Maximum allowed size for bar
BarMaxLine= BarChartMidY + .26 - Cushion;
BarMinLine= BarChartMidY - .26 + Cushion;
SodiumColor=   [1 0 0];
PotassiumColor=[1 .9 0];
AMPAColor=     [0 1 1];
NMDAColor=     [0 0 1];
CapColor=      [.8 .5 .5];
PasColor=      [0 1 0];


%Axial Graph settings
DifftoZero=min(ceil(volt(:)));                     %Takes smallest value in volt
VoltRange= abs( max(ceil(volt(:))) - DifftoZero);  %Range of Volt; works {++,+-,-+,--}
VoltageCeiling=abs(50);                     %Highest voltage mapped in colormap is 50mV
VoltageFloor=abs(-80) ;                      %Lowest voltage mapped in colormap is -80mV
boxcolormap=colormap(jet(VoltageCeiling+VoltageFloor));              %Sets range-based Jet colormap
AxialScaler=(.9*SpaceConstant)/max(abs(axial(:))); %Multiplies with axial current to fit in compartment
AxialZoom=1;                                    %Zoom on axial bars
MaxAxial=.9*SpaceConstant;
BoxChartMidY=.625;                                       %Midpoint of Box chart
BoxMaxLine=BoxChartMidY+ .075 - Cushion;
BoxMinLine=BoxChartMidY- .075 + Cushion;

BoxScaler=1/max(diam) * (.15 - 2*Cushion);         %*(.33) for scale to 1/3 of figure



%Voltage Line Chart settings
LineChartMidY= .85;
LineMaxLine=LineChartMidY +.12 - Cushion;
LineMinLine=LineChartMidY -.12 + Cushion;
MaxVolt=max(volt(:));
MinVolt=min(volt(:));
LineZeroMv=(abs(MinVolt)/((abs(MinVolt) + MaxVolt)))*(LineMaxLine-LineMinLine)+LineMinLine;
VoltScaler=(1/max(abs(volt(:))))*(LineMaxLine-LineMinLine);



%Current input indicator settings
NumberOfInputs=1;           %Set the number of inputs, unimplemented 
InputCompartment=4;         %Set the compartment where input arrives
InputColor = NMDAColor;     %set the input color. See ion channel graph settings, or make up your own [R G B];


clf;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Contextual Voltage charts %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

voltI=volt';
PlotWidth=.33;
PlotHeight=.42;
PlotX=.665;
SomaPlotY=.53;
SelectedPlotY=.05;
SomaCompartment=1;
SelectedCompartment=5;     %Choose which voltage compartment to show in bottom right
PlotLineXScalar= PlotWidth/(EndTime-StartTime);
SomaPlotZeroMv=(abs(MinVolt)/((abs(MinVolt) + MaxVolt)))*(PlotHeight)+SomaPlotY;
SelectedPlotZeroMv=(abs(MinVolt)/((abs(MinVolt) + MaxVolt)))*(PlotHeight)+SelectedPlotY;
PlotYScalar=(1/(abs(MinVolt)+MaxVolt))  *PlotHeight;
TimeSpan=(EndTime-StartTime)/10;


annotation('textbox', [PlotX+1/3*PlotWidth SomaPlotY+PlotHeight .3 .03],...
    'String', 'Voltage near soma',...
    'LineStyle', 'none');
SomaPlot=axes('Position', [PlotX SomaPlotY PlotWidth PlotHeight]);
plot(SomaPlot, voltI(StartTime:EndTime,SomaCompartment),'g');
ylim(SomaPlot,[MinVolt MaxVolt]);
xlim(SomaPlot,[1 EndTime-StartTime]);
xlabel(SomaPlot,'ms')
ylabel(SomaPlot,'mV')
XTickMarks=get(gca,'XTick');
AdjustedTick=(XTickMarks+StartTime)/10;
set(SomaPlot, 'XTickLabel', AdjustedTick );



annotation('textbox', [PlotX+1/4*PlotWidth SelectedPlotY+PlotHeight .25 .03],...
    'String', 'Voltage at stimulated compartment',...
    'LineStyle', 'none');
SelectedPlot=axes('Position', [PlotX SelectedPlotY PlotWidth PlotHeight]);
plot(SelectedPlot, voltI(StartTime:EndTime,SelectedCompartment), 'b');
ylim(SelectedPlot,[MinVolt MaxVolt]);
xlim(SelectedPlot,[1 EndTime-StartTime]);
xlabel(SelectedPlot,'ms')
ylabel(SelectedPlot,'mV')
set(SelectedPlot, 'XTickLabel', AdjustedTick );



%Creates a '+' on current time
SomaPlotLine1=annotation('line', [PlotX PlotX], [SomaPlotY SomaPlotY+PlotHeight],...
    'LineWidth', .0001);
SomaPlotLine2=annotation('line', [PlotX PlotX], [SomaPlotY SomaPlotY+PlotHeight],...
    'LineWidth', .0001);

SelectedPlotLine1=annotation('line', [PlotX PlotX], [SelectedPlotY SelectedPlotY+PlotHeight],...
    'LineWidth', .0001);
SelectedPlotLine2=annotation('line', [PlotX PlotX], [SelectedPlotY SelectedPlotY+PlotHeight],...
    'LineWidth', .0001);




arrowloop=1;
while arrowloop<=maxcompart
    BoxX(arrowloop)=SpaceConstant*arrowloop-SpaceConstant;
    arrowloop=arrowloop+LoopAdd;
end




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



TimeText=['TIME: ', num2str(CurrentTime/10),'ms'];
TimeDisplay=annotation('textbox', [.4 .975 .2 .03],...
    'String', TimeText,...
    'LineStyle', 'none',...
    'FontSize', .03,...
    'HorizontalAlignment', 'center');



%Legend display%%%%%%%%%%%%%%

LegCush=.0025; %buffer between graph data and borders
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [BarMaxLine BarMinLine],...
    'LineWidth', 5);
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [BarMaxLine BoxMinLine],...
    'LineWidth', 2,...
    'LineStyle', ':');
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [BoxMaxLine BoxMinLine],...
    'LineWidth', 5);
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [LineMaxLine BarMinLine],...
    'LineWidth', 2,...
    'LineStyle', ':');
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [LineMaxLine LineMinLine],...
    'LineWidth', 5);


%%%%%%%%%%%%%%
% Bar Legend %
%%%%%%%%%%%%%%

%Bar chart
BarZoom = ((BarMaxLine-BarMinLine)/2)/BarLimit;

BarMaxStr=[num2str(((BarMaxLine-BarMinLine)/2)/BarZoom), ' nA'];
annotation('textbox',[LegendStart+.003, BarMaxLine-.5*Cushion-.01, .1, .05],... %-.5*Cushion for ideal alignment
    'String', BarMaxStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');


BarMinStr=[num2str(((BarMaxLine-BarMinLine)/2)/BarZoom*-1), ' nA'];
annotation('textbox',[LegendStart+.003, BarMinLine-.5*Cushion, .1, .05],...
    'String', BarMinStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');


BoxMaxStr=[num2str(round(10*max(diam))/10), ' µm'];
annotation('textbox',[LegendStart+.003, BoxMaxLine-.5*Cushion-.01, .06, .02],...
    'String', BoxMaxStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

BoxMidStr=[num2str(round(10*max(diam))/20), ' µm'];
annotation('textbox',[LegendStart+.003, BoxChartMidY-.01, .06, .02],...
    'String', BoxMidStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'middle');


BoxMinStr='0 µm';
annotation('textbox',[LegendStart+.003, BoxMinLine-.5*Cushion, .06, .02],...
    'String', BoxMinStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

%Distance from soma legend
annotation('textbox',[0 BoxMinLine-.023 .06 .1],...
    'String', strcat(num2str(round(min(distance))), ' µm      from soma'),...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');
annotation('textbox',[LegendStart-.061 BoxMinLine-.023 .06 .1],...
    'String', strcat(num2str(round(max(distance))), ' µm from soma'),...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom',...
    'HorizontalAlignment', 'right');


%Dendrite length legend
dendriteLengthStart=.02;
annotation('arrow', [dendriteLengthStart+.10 dendriteLengthStart+.25], [LineMaxLine+.02 LineMaxLine+.02])
annotation('textbox',[dendriteLengthStart LineMaxLine+.01 .8 .04],...
    'String', 'Dendrite Length',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');


%Volt Line Chart%%%%%%%%%%%%%%%%%%

%Max mV string
LineMaxStr=[num2str(round(MaxVolt)), ' mV'];
annotation('textbox',[LegendStart+.003, LineMaxLine-.5*Cushion-.005, .1, .05],...
    'String', LineMaxStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

%Min mV string
LineMinStr=[num2str(round(MinVolt)) ' mV'];
annotation('textbox',[LegendStart+.003, LineMinLine-.5*Cushion-.005, .1, .05],...
    'String', LineMinStr,...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');
annotation('line', [0 LegendStart], [LineMinLine LineMinLine],...
    'LineStyle', '--');


%0 mV String
annotation('textbox',[LegendStart+.003, LineZeroMv-.01, .1, .05],...
    'String', '0 mV',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');
annotation('line', [0 LegendStart], [LineZeroMv LineZeroMv],...
    'LineStyle', '--');






%Ion Bar chart%%%%%%%%%%%%%%%%%%%%%%%

%currents tag
annotation('textbox',[LegendStart+.012, BarChartMidY+.105, .049, .024],...
    'String', 'Currents',...
    'LineStyle', ':',...
    'VerticalAlignment', 'middle');



%Sodium Legend
annotation('rectangle', ... #x, y, width, height
    [LegendStart+.01 BarChartMidY-.015 .006 .02],...
    'FaceColor',SodiumColor,... %R G B
    'LineWidth', .0005);
annotation('textbox',[LegendStart+.012, BarChartMidY-.015, .1, .02],...
    'String', '  Na+',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');


%Potassium Legend
annotation('rectangle', ... #x, y, width, height
    [LegendStart+.01 BarChartMidY+.015 .006 .02],...
    'FaceColor',PotassiumColor,... %R G B
    'LineWidth', .0005);
annotation('textbox',[LegendStart+.012, BarChartMidY+.015, .1, .02],...
    'String', '  K+',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

%AMPA Legend
annotation('rectangle', ... #x, y, width, height
    [LegendStart+.01 BarChartMidY-.045 .006 .02],...
    'FaceColor',AMPAColor,... %R G B
    'LineWidth', .0005);
annotation('textbox',[LegendStart+.012, BarChartMidY-.045, .1, .02],...
    'String', '  AMPA',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

%NMDA Legend
annotation('rectangle', ... #x, y, width, height
    [LegendStart+.01 BarChartMidY-.075 .006 .02],...
    'FaceColor',NMDAColor,... %R G B
    'LineWidth', .0005);
annotation('textbox',[LegendStart+.012, BarChartMidY-.075, .1, .02],...
    'String', '  NMDA',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

%Capacitive Legend
annotation('rectangle', ... #x, y, width, height
    [LegendStart+.01 BarChartMidY+.075 .006 .02],...
    'FaceColor',CapColor,... %R G B
    'LineWidth', .0005);
annotation('textbox',[LegendStart+.012, BarChartMidY+.075, .1, .02],...
    'String', '  Capacitive',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');

%Passive Legend
annotation('rectangle', ... #x, y, width, height
    [LegendStart+.01 BarChartMidY+.045 .006 .02],...
    'FaceColor',PasColor,... %R G B
    'LineWidth', .0005);
annotation('textbox',[LegendStart+.012, BarChartMidY+.045, .1, .02],...
    'String', '  Leak',...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');


annotation('textarrow', [LegendStart+.025 LegendStart+.025], [BarChartMidY+.17 BarChartMidY+.21],...
    'String' , 'Out')

annotation('textarrow', [LegendStart+.02 LegendStart+.02], [BarChartMidY-.17 BarChartMidY-.21],...
    'String' , 'In')


%axial legend
annotation('line', [BoxX(4) BoxX(4)],[BoxMinLine BoxMinLine-.025])
annotation('rectangle',...
    [BoxX(4)-.5*SpaceConstant BoxMinLine-.02 .5*SpaceConstant .012],...
    'LineWidth', .0001, ...
    'FaceColor', [.2 .1 .1]);

AxialLegSize=round(.5/AxialZoom*100)/100;
annotation('textbox',[BoxX(4) BoxMinLine-.025 .05 .04],...
    'String', strcat(num2str(AxialLegSize), 'nA'),...
    'LineStyle', 'none',...
    'VerticalAlignment', 'bottom');



caxis([-1*VoltageFloor VoltageCeiling])
cb=colorbar([LegendStart+.047 BoxMinLine .015 BoxMaxLine-BoxMinLine]);
%set(cb, 'peer', gca, [LegendStart-.40 BoxMaxLine+.025 0.12 0.035]);
annotation('textbox', [LegendStart+.045 BoxMinLine-.04 .04 .04],...
    'String', 'mV',...
    'LineStyle', 'none');

%Line Chart - Voltage string
annotation('textarrow', [LegendStart+.01 LegendStart+.01], [LineChartMidY-.03 LineChartMidY+.03],...
    'String', 'Voltage',...
    'HorizontalAlignment','left');





%Setting up display



arrowloop=1;
while arrowloop<=maxcompart
    if continued==false
        break;
    end
    
    
    %Midlines
    annotation('line', [LineX1 LineX2], [BarChartMidY BarChartMidY]);
    
    
    
    %Capacitive current
    CapBarSize=min(MaxBar, BarZoom*AbsCap(arrowloop, CurrentTime));
    if cap(arrowloop, CurrentTime)>0
        
        CapBar(arrowloop)=annotation('rectangle',...
            [BarX BarChartMidY-.0005 BarWidth CapBarSize],...
            'FaceColor',CapColor,...
            'LineWidth', .0005);
        
    else
        CapBar(arrowloop)=annotation('rectangle',...
            [BarX BarChartMidY-CapBarSize BarWidth CapBarSize],...
            'FaceColor',CapColor,...
            'LineWidth', .0005);
    end
    CapX(arrowloop)= BarX;
    BarX= BarX + BarWidth;
    
    %Passive current
    PasBarSize=min(MaxBar, BarZoom*AbsPas(arrowloop, CurrentTime));
    PasBar(arrowloop)=annotation('rectangle',...
        [BarX BarChartMidY-.0005 BarWidth PasBarSize],...
        'FaceColor',PasColor,...
        'LineWidth', .0005);
    PasX(arrowloop)=BarX;
    BarX= BarX + BarWidth;
    
    
    
    %Potassium current
    PotassiumBarSize=min(MaxBar, BarZoom*AbsK(arrowloop, CurrentTime));
    PotassiumBar(arrowloop)=annotation('rectangle',...
        [BarX BarChartMidY-.0005 BarWidth PotassiumBarSize],...
        'FaceColor',PotassiumColor,...
        'LineWidth', .0005);
    PotassiumX(arrowloop)= BarX;
    BarX=BarX+BarWidth;
    
    %Sodium
    SodiumBarSize=min(MaxBar, BarZoom*AbsNa(arrowloop, CurrentTime));
    SodiumBar(arrowloop)=annotation('rectangle', ... #x, y, width, height ; preallocating makes no speed difference
        [BarX BarChartMidY-SodiumBarSize BarWidth SodiumBarSize],...
        'FaceColor',SodiumColor,... %R G B
        'LineWidth', .0005);
    SodiumX(arrowloop)= BarX;
    
    
    BarX=BarX+BarWidth;    %Set next bar
    
    
    
    
    %AMPA current
    
    AMPABarSize=min(MaxBar, BarZoom*AbsAMPA(arrowloop, CurrentTime));
    AMPABar(arrowloop)=annotation('rectangle',...
        [BarX BarChartMidY-AMPABarSize BarWidth  AMPABarSize],...
        'FaceColor',AMPAColor,...
        'LineWidth', .0005);
    
    AMPAX(arrowloop)= BarX;
    BarX=BarX+BarWidth;
    
    %NMDA current
    NMDABarSize=min(MaxBar, BarZoom*AbsNMDA(arrowloop, CurrentTime));
    NMDABar(arrowloop)=annotation('rectangle',...
        [BarX BarChartMidY-NMDABarSize BarWidth NMDABarSize],...
        'FaceColor',NMDAColor,...
        'LineWidth', .0005);
    
    NMDAX(arrowloop)= BarX;
    
    
    
    
    %Move to next compartment
    LineX1 =LineX1 + SpaceConstant;
    LineX2 =LineX2 + SpaceConstant;
    BarX=LineX1;
    
    
    %Box Chart
    BoxSize=BoxScaler*diam(arrowloop);          %Scales current value to range of rendering
    BoxFromBot=BoxChartMidY-.5*BoxSize;               %Determines lowest point of box; subtracts half box size from midline
    
    ColorNumber=ceil(volt(arrowloop,CurrentTime))+abs(DifftoZero);
    BarColor=[boxcolormap(ColorNumber,1) boxcolormap(ColorNumber,2) boxcolormap(ColorNumber,3)];
    
    DiamBar(arrowloop)=annotation('rectangle',[BoxX(arrowloop) BoxFromBot SpaceConstant BoxSize],...
        'FaceColor', BarColor,...
        'EdgeColor', 'none'); %fromleft frombottom width height
    
    
    
    %Current Input Indicator
    if(arrowloop==InputCompartment)
        annotation('arrow', [BoxX(InputCompartment)+.5*BoxX(2) BoxX(InputCompartment)+.5*BoxX(2)],...
            [BoxChartMidY+.5*BoxSize+.018 BoxChartMidY+.5*BoxSize+.019],...
            'HeadStyle', 'plain',...
            'HeadWidth', 15,...
            'HeadLength', 15,...
            'Color', InputColor);
        annotation('line', [BoxX(InputCompartment)+.5*BoxX(2) BoxX(InputCompartment)+.5*BoxX(2)],...
            [BoxChartMidY+.5*BoxSize+.06 BoxChartMidY+.5*BoxSize+.02]);
    annotation('textbox',[BoxX(InputCompartment)+.5*BoxX(2)+.002 BoxChartMidY+.5*BoxSize+.025 .05 .05],...
        'String', 'Input',...
   'LineStyle', 'none',...
    'VerticalAlignment', 'middle',...
    'FontWeight', 'normal');
    end
    
    %Axial current
    ScaledArrowX= AxialScaler*axial(arrowloop,CurrentTime); %Sets range to -1 to 1
    ArrowX2=max(.001,min(1, -1*ScaledArrowX)); % *-1 to correct axial directions
    
    AxialBox(arrowloop)=annotation('rectangle',...
        [BoxX(arrowloop) .49 ArrowX2 .012],...    %Draws
        'EdgeColor', 'none', ...
        'FaceColor', [.2 .1 .1]);
    
    
    %Line Chart
    if(arrowloop==1)
        
        VoltLine(arrowloop)=annotation('line', [BoxX(arrowloop) (BoxX(arrowloop)+.5*BoxX(2))], [.2 .2],...
            'Color', [.5 .2 1],...
            'LineWidth', 2);
    elseif(arrowloop==maxcompart)
        VoltLine(arrowloop)=annotation('line', [BoxX(arrowloop)-.5*BoxX(2) (BoxX(arrowloop)+.5*BoxX(2))], [.2 .2],...
            'Color', [.5 .2 1],...
            'LineWidth', 2);
        
        
    else
            
        VoltLine(arrowloop)=annotation('line', [BoxX(arrowloop)-.5*BoxX(2) (BoxX(arrowloop)-.5*BoxX(2)+SpaceConstant)], [.2 .2],...
            'Color', [.5 .2 1],...
            'LineWidth', 2);
    end
    
    
    
    %Vertical dotted lines
    annotation('line', [BoxX(arrowloop) BoxX(arrowloop)], [BoxFromBot+BoxSize BoxMaxLine], ...
        'LineStyle', ':',...
        'LineWidth', .1);
    annotation('line', [BoxX(arrowloop) BoxX(arrowloop)], [BoxFromBot BoxMinLine], ...
        'LineStyle', ':',...
        'LineWidth', .1);
    
    annotation('line', [BoxX(arrowloop) BoxX(arrowloop)], [BarMaxLine BarMinLine], ...
        'LineStyle', ':',...
        'LineWidth', .1);
    
    annotation('line', [BoxX(arrowloop) BoxX(arrowloop)], [LineMaxLine LineMinLine], ...
        'LineStyle', ':',...
        'LineWidth', .1);
    
    
    arrowloop=arrowloop+LoopAdd;
end

ExtendVoltLine=annotation('line', [BoxX(maxcompart)+.5*BoxX(2) BoxX(maxcompart)+SpaceConstant], [.2 .2],...
    'Color', [.5 .2 1],...
    'LineWidth', 2);


if recordmovie==true
    writerObj= VideoWriter(strcat(Filename, '_movie',date,'.avi'));
    writerObj.FrameRate=10;
    open(writerObj);
end


%-------------Main Display Loop-----------------%
while CurrentTime<EndTime && continued==true  %maxtime
    tic %measures loop speed to smooth display when recording is off
    
    str3=['TIME: ',num2str(CurrentTime/10),'ms'];
    
    set(TimeDisplay, 'String', str3) %(closing window midway causes program to end here, no problem)
    arrowloop=1;
    while arrowloop<=maxcompart
        
        SodiumBarSize=min(MaxBar, BarZoom*AbsNa(arrowloop, CurrentTime));
        SodiumBarPos=[SodiumX(arrowloop) BarChartMidY-SodiumBarSize BarWidth SodiumBarSize];
        set(SodiumBar(arrowloop),'Position', SodiumBarPos);
        
        PotassiumBarSize=min(MaxBar, BarZoom*AbsK(arrowloop, CurrentTime));
        PotassiumBarPos=[PotassiumX(arrowloop) BarChartMidY-.0005 BarWidth PotassiumBarSize];
        set(PotassiumBar(arrowloop),'Position', PotassiumBarPos);
        
        AMPABarSize=min(MaxBar, BarZoom*AbsAMPA(arrowloop, CurrentTime));
        AMPABarPos=[AMPAX(arrowloop) BarChartMidY-AMPABarSize BarWidth AMPABarSize];
        set(AMPABar(arrowloop),'Position', AMPABarPos);
        
        
        NMDABarSize=min(MaxBar, BarZoom*AbsNMDA(arrowloop, CurrentTime));
        NMDABarPos=[NMDAX(arrowloop) BarChartMidY-NMDABarSize BarWidth NMDABarSize];
        set(NMDABar(arrowloop),'Position', NMDABarPos);
        
        
        if cap(arrowloop, CurrentTime)>0
            
            CapBarSize=min(MaxBar, BarZoom*AbsCap(arrowloop, CurrentTime));
            CapBarPos=[CapX(arrowloop) BarChartMidY-.0005 BarWidth CapBarSize];
            set(CapBar(arrowloop),'Position', CapBarPos);
            
        else
            
            CapBarSize=min(MaxBar, BarZoom*AbsCap(arrowloop, CurrentTime));
            CapBarPos=[CapX(arrowloop) BarChartMidY-CapBarSize BarWidth CapBarSize];
            set(CapBar(arrowloop),'Position', CapBarPos);
        end
        
        PasBarSize=min(MaxBar, BarZoom*AbsPas(arrowloop, CurrentTime));
        PasBarPos=[PasX(arrowloop) BarChartMidY-.0005 BarWidth PasBarSize];
        set(PasBar(arrowloop),'Position', PasBarPos);
        
        
        %Bar Chart
        ColorNumber=ceil(volt(arrowloop,CurrentTime))+VoltageFloor;
        BarColor=[boxcolormap(ColorNumber,1) boxcolormap(ColorNumber,2) boxcolormap(ColorNumber,3)];
        
        set(DiamBar(arrowloop),'FaceColor',BarColor);
        
        ScaledArrowX= min(MaxAxial,AxialZoom*AxialScaler*axial(arrowloop,CurrentTime));  %Sets range to -1 to 1
        ArrowX2=abs(min(1, -1*ScaledArrowX)); % *-1 to correct axial directions
        
        if(axial(arrowloop,CurrentTime)<0)
            AxialBoxPosition=[BoxX(arrowloop) BoxChartMidY-.01 ArrowX2 .012];
        else
            AxialBoxPosition=[BoxX(arrowloop)-ArrowX2 BoxChartMidY-.01 ArrowX2 .012];
        end
        
        set(AxialBox(arrowloop),'Position', AxialBoxPosition);
        
        
        %Line chart
        
        VLY1=VoltScaler*volt(arrowloop,CurrentTime);
        if arrowloop~=maxcompart %Is not equal to
            VLY2=VoltScaler*volt(arrowloop+1,CurrentTime);
        end
        VoltLineY= [(VLY1+LineZeroMv) (VLY2+LineZeroMv)];
        set(VoltLine(arrowloop),'Y', VoltLineY);
        
        if(arrowloop==maxcompart)
            VLY3= VLY1 - (VLY2-VLY1)/2;
            ExtendVoltLineY=[VLY3+LineZeroMv (VLY1+LineZeroMv)];
            set(ExtendVoltLine,'Y', ExtendVoltLineY);
        end
        
        %Contextual charts
        PlotScaledTime=CurrentTime-StartTime;
        
        SomaY=voltI(CurrentTime, 1) * PlotYScalar;
        SelectedY=voltI(CurrentTime, SelectedCompartment) * PlotYScalar;
        
        
        
        set(SomaPlotLine1, 'X', [PlotLineXScalar*PlotScaledTime+PlotX-.0025 PlotLineXScalar*PlotScaledTime+PlotX+.0025],...
            'Y', [SomaY+SomaPlotZeroMv SomaY+SomaPlotZeroMv]);
        set(SomaPlotLine2, 'X', [PlotLineXScalar*PlotScaledTime+PlotX PlotLineXScalar*PlotScaledTime+PlotX],...
            'Y', [SomaY+SomaPlotZeroMv-.005 SomaY+SomaPlotZeroMv+.005]);
        
        
        
        set(SelectedPlotLine1, 'X', [PlotLineXScalar*PlotScaledTime+PlotX-.0025 PlotLineXScalar*PlotScaledTime+PlotX+.0025],...
            'Y', [SelectedY+SelectedPlotZeroMv SelectedY+SelectedPlotZeroMv]);
        
        set(SelectedPlotLine2, 'X', [PlotLineXScalar*PlotScaledTime+PlotX PlotLineXScalar*PlotScaledTime+PlotX],...
            'Y', [SelectedY+SelectedPlotZeroMv-.005 SelectedY+SelectedPlotZeroMv+.005]);
        
        
        arrowloop=arrowloop+LoopAdd;
        
        
    end
    
    
    
    drawnow;
    if recordmovie==true
        currentframe=getframe(gcf);
        writeVideo(writerObj, currentframe); %Quitting the window with recording on will end here. Video may still record.
    end
    
    loopspeed=toc;
    if (loopspeed<.3 && recordmovie==false)
        pause(.3-loopspeed); %Pause between switching frames
    end
    
    CurrentTime = CurrentTime + steps; %Update time loop
    
end %End main loop
if recordmovie==true
    close(writerObj);
end
close all;
end %End Function



















