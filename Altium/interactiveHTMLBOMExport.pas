
 https://github.com/Altium-Designer-addons/scripts-libraries/tree/master/XIA_Release_Manager
 Altium API Doku http://wiki.altium.com/plugins/viewsource/viewpagesrc.action?pageId=3080340
{***************************************************************************   }

uses
    SysUtils;
    IniFiles;

const
    constStringEquals = '=';

var
   primesReleaserParms: TStringList;

procedure iBOMFormat();
var
  currentProject : IProject;
  projectFileName : TString;
  projectBasePath : TString;
  pcbDoc : IDocument;
  bomFilePath: TString;
  bomFileContent: TString;
  htmlfilePath: TString;
  templateFilePath: Tstring;
  bomFile: TextFile;
  htmlFile: TextFile;
  templateFile : TextFile;
  currentline :TString;

  json_metadata : TString;
  json_edges_bbox   : TString;
  json_ibom_version   : TString;
  json_edges : TString;

  json_bom :TString;
  json_bom_F :TString;
  json_bom_B :TString;
  json_bom_both :TString;
  json_bom_skipped :TString;
  json_bomrow : TString;

  layer: TString; //Stores Top or Bottom Layoer

  json_modules : TString;
  json_moudule_pads :    TString;
  json_module_drawings : TString;


  SchComponent : IComponent;
  Track                   : IPCB_Primitive;
    TrackIteratorHandle     : IPCB_GroupIterator;
    Component               : IPCB_Component;
    Board                   : IPCB_Board;
    ComponentIteratorHandle : IPCB_BoardIterator;
    OutlineIteratorHandle : IPCB_BoardIterator;
    ParameterIteratorHandle: ISch_Iterator;
    S                       : TPCBString;
    TrackCount              : Integer;
    MaxX                    : Integer;
    MinX                    : Integer;
    MaxY                    : Integer;
    MinY                    : Integer;
    X                       : Integer;
    Y                       : Integer;
    Size                    : Integer;
    TextLength              : Integer;
    Designator              : IPCB_Text;
    PCBSystemOptions        : IPCB_SystemOptions;
    DRCSetting              : boolean;
    R                       : TCoordRect;

    I: Integer;
begin

  DecimalSeparator := '.';

  currentProject := GetWorkspace.DM_FocusedProject;
  If currentProject = Nil Then ExitWithWriteToDebugFile(0,'No project selected.');

  projectBasePath:=currentProject.DM_ProjectFullPath;
  projectFileName:=currentProject.DM_ProjectFileName;
    //ShowMessage(projectFileName);

  primesReleaserParms:= TStringList.Create;
  primesReleaserParms.Add('projectName' + constStringEquals + projectFileName);
  primesReleaserParms.Add('projectBasePath' + constStringEquals + projectBasePath);

  pcbDoc := currentProject.DM_PrimaryImplementationDocument()  ;

  //ShowMessage(pcbDoc.DM_FileName());

    //ShowMessage(projectFileName);

    If PCBServer = Nil Then Exit;

       // Verify that the document is a PcbDoc
     if PCBServer.GetPCBBoardByPath(pcbDoc.DM_FullPath()) = Nil Then Exit;
     Board :=  PCBServer.GetPCBBoardByPath(pcbDoc.DM_FullPath())     ;

     // Disables Online DRC during designator movement to improve speed
     PCBSystemOptions := PCBServer.SystemOptions;

     If PCBSystemOptions = Nil Then Exit;

     DRCSetting := PCBSystemOptions.DoOnlineDRC;
     PCBSystemOptions.DoOnlineDRC := false;

    //ShowMessage(LayerSet.MechanicalLayers.ToString);

                 MaxX:= 0;
             MinX:= 999999999;

             MaxY:= 0;

            MinY:= 999999999;
    json_edges := '"edges":[';

    try
       PCBServer.PreProcess;
       OutlineIteratorHandle := Board.BoardIterator_Create;
       OutlineIteratorHandle.AddFilter_ObjectSet(MkSet(eTrackObject));
       OutlineIteratorHandle.AddFilter_IPCB_LayerSet(LayerSet.Factory(59));  //Seems to be mechanical 3
       OutlineIteratorHandle.AddFilter_Method(eProcessAll);

       Track := OutlineIteratorHandle.FirstPCBObject;
        while (Track <> Nil) Do
        begin
            ShowMessage(Track.Detail+' Layer'+IntToStr(Track.Layer)+' Pos ');
            ///ShowMessage(CoordToMMs(Track.X1));
            if Track.X1>= MaxX then MaxX:=Track.X1;
            if Track.X1<= MinX then MinX:=Track.X1;

            if Track.X2>= MaxX then MaxX:=Track.X2;
            if Track.X2<= MinX then MinX:=Track.X2;

            if Track.Y1>= MaxY then MaxY:=Track.Y1;
            if Track.Y1<= MinY then MinY:=Track.Y1;

            if Track.Y2>= MaxY then MaxY:=Track.Y2;
            if Track.Y2<= MinY then MinY:=Track.Y2;

            json_edges := json_edges + '{"type":"segment","start":['
            +FloatToStr(CoordToMMs(Track.X1))+','
            +FloatToStr(CoordToMMs(Track.Y1))+'],"end":['
            +FloatToStr(CoordToMMs(Track.X2))+','
            +FloatToStr(CoordToMMs(Track.Y2))+'],"width":"'+FloatToStr(CoordToMMs(Track.Width))+'"'
            +'}';

                Track := OutlineIteratorHandle.NextPCBObject;
                if(Track <> Nil) then
                begin
                  json_edges := json_edges + ',';
                end;
        end;

    finally
    end;

    json_edges_bbox :=  '"edges_bbox":{"minx": "'+FloatToStr(CoordToMMs(minX))+'", "miny":"'+FloatToStr(CoordToMMs(minY))+'","maxx":"'+FloatToStr(CoordToMMs(maxX))+'","maxy":"'+FloatToStr(CoordToMMs(maxY))+'"}';

    json_edges := json_edges+']';

    //ShowMessage('Board: '+FloatToStr(CoordToMMs(Board.XOrigin))+','+FloatToStr(CoordToMMs(Board.YOrigin))+' X: '+FloatToStr(CoordToMMs(minX))+', '+FloatToStr(CoordToMMs(maxX))+' Y: '+FloatToStr(CoordToMMs(minY))+', '+FloatToStr(CoordToMMs(maxY)));

    json_bom := '"bom":{';
    json_bom_F := '"F":[';
    json_bom_B := '"B":[';
    json_bom_both := '"both":[';
    json_bom_skipped := '"skipped":[';
    json_modules := '"modules":[';

    try
        // Notify the pcbserver that we will make changes

        ComponentIteratorHandle := PCBServer.GetPCBBoardByPath(pcbDoc.DM_FullPath()).BoardIterator_Create;
        ComponentIteratorHandle.AddFilter_ObjectSet(MkSet(eComponentObject));
        ComponentIteratorHandle.AddFilter_IPCB_LayerSet(LayerSet.AllLayers);
        ComponentIteratorHandle.AddFilter_Method(eProcessAll);

        S := '';
        i:=0;

        Component := ComponentIteratorHandle.FirstPCBObject;
        while (Component <> Nil) Do
        begin

             i := i+1;
             MaxX:= 0;
             MinX:= 999999999;

             MaxY:= 0;
             MinY:= 999999999;

             TrackCount :=0;

             if(Component.Layer = 1) then //TOP
             begin
               layer:='F';
             end
             else
             //if(Component.Layer = 32) then //BOtTOM
             begin
               layer:='B';
             end;
             //ShowMessage(Component.Name.Text);

             json_modules := json_modules
             +'{'
                          +'"pads":[],'
                          +'"ref":"'+Component.Name.Text+'",'
                          +'"bbox":{'
                                   //+'"relpos":['+FloatToStr(CoordToMMs(Component.x))+','+FloatToStr(CoordToMMs(Component.y))+'],'
                                   +'"relpos":['+'0'+','+'0'+'],'
                                   +'"angle":'+FloatToStr(CoordToMMs(Component.Rotation))+','
                                   +'"pos":['+FloatToStr(CoordToMMs(Component.x))+','+FloatToStr(CoordToMMs(Component.y))+'],'
                                   +'"size":['+'10'+','+'15'+']'
                          +'},'
                          +'"layer":["'
                          +layer
                          +'"],'//TODO: on top or bottom
                          +'"drawings":[]'

             +'}';

             //to get the schematic parameters we need to iterate all flat chem objects and compare the unique ide ?! Really?

             //SchComponent := FlatHierarchy.DM_Components(0);

             {ParameterIteratorHandle := Component.SourceUniqueId.SchIterator._Create;
             ParameterIteratorHandle.AddFilter_ObjectSet(MkSet(eParameter));
             Parameter := ParameterIteratorHandle.FirstSchObject;
             while Parameter <> nil do
             begin
                  if(UpperCase(Parameter.Name) = 'Value') then
                     ShowMessage(Parameter.Value);
                  begin
                  end;
                  Parameter := ParameterIteratorHandle.NextSchObject;
             end;
             }

             //json_bom_skipped:=json_bom_skipped +IntToStr(i)+',';



             json_bomrow := '['
             +'1,'
             +'"'+'value'+IntToStr(i)+'",'     //TODO: Value
             +'"'+Component.FootprintDescription+'",'  //TOD= Footpring
             +'[["'+Component.Name.Text+'",1'+IntToStr(i)++']],'  //TODO: Part Name and Unique id
             +'{"val":"1","unit":"r"}' //TODO: extra data
             +']';

             if(layer='F') then
             begin
                  json_bom_F := json_bom_F + json_bomrow;
             end;
             if(layer='B') then
             begin
                  json_bom_B := json_bom_B + json_bomrow;
             end;
             json_bom_both := json_bom_both + json_bomrow;

             Component := ComponentIteratorHandle.NextPCBObject;
             if(Component <> Nil) then
                begin
                  json_modules := json_modules +',';
                  if(layer='F') then
                  begin
                     json_bom_F := json_bom_F +',';
                  end;
                  if(layer='B') then
                  begin
                     json_bom_B := json_bom_B +',';
                  end;
                  json_bom_both := json_bom_both +',';
             end;


        end;

    finally
        // Restore DRC setting
         PCBSystemOptions.DoOnlineDRC :=  DRCSetting;
    end;

    json_modules := json_modules + ']';

    if(AnsiLastChar(json_bom_skipped)=',')then
    begin
      json_bom_skipped:=leftStr(json_bom_skipped,Length(json_bom_skipped)-1);
    end;
    if(AnsiLastChar(json_bom_F)=',')then
    begin
      json_bom_F:=leftStr(json_bom_F,Length(json_bom_F)-1);
    end;
    if(AnsiLastChar(json_bom_B)=',')then
    begin
      json_bom_B:=leftStr(json_bom_B,Length(json_bom_B)-1);
    end;

    json_bom_skipped := json_bom_skipped +']';
    json_bom_F := json_bom_F +']';
    json_bom_B := json_bom_B +']';
    json_bom_both := json_bom_both +']';

    json_bom := json_bom + json_bom_F +','+ json_bom_B +','+json_bom_both++','+json_bom_skipped+ '}';


    json_metadata :=    '"metadata":{"date":"2020-07-24 12:28:12","company":"Primes GmbH","revision":"A","title":"Duena_epaper"}';

    json_ibom_version :=  '"ibom_version":"v2.3-6-g76304"';

    bomFilePath := 'c:\Temp\ADreleaseTemp\ibom.json';
    bomFileContent := '{'+json_ibom_version+','+json_modules+','+json_edges_bbox+','+json_bom+','+json_edges+','+json_metadata+'}'   ;
    htmlFilePath := 'c:\Temp\ADreleaseTemp\ibom.html';
    templateFilePath := 'c:\Temp\ADreleaseTemp\ibom.html.template';

    try
       AssignFile(htmlFile, htmlFilePath);
       AssignFile(templateFile, templateFilePath);
       AssignFile(bomFile, bomFilePath);
       ReWrite(bomFile);
       ReWrite(htmlFile);
       reset(templateFile);
       WriteLn(bomFile, bomFileContent);
       //WriteLn(htmlFile, 'pcbdata=JSON.parse('+chr(39)+'{'+bomFileContent+'}'+chr(39)+');');

      while not eof(templateFile) do
      begin
        ReadLn(templateFile, currentline);
        if(currentline=null)then
        begin
             currentline:='';
        end;
        if(currentline='//INSERTBOMDATAHERE') then
        begin
             currentline:='pcbdata=JSON.parse('+chr(39)+bomFileContent+chr(39)+');'
        end;
        WriteLn(htmlFile, currentline)
      end;

    finally
       CloseFile(htmlFile);
       CloseFile(bomFile);
       CloseFile(templateFile);
    end;
  end;
