function getNetsJSON(Board: IPCB_Board): TString;

var
    currentProject : IProject;
    NetObjectIteratorHandle : IPCB_BoardIterator;
    Net: IPCBPrimitive;

    json_nets: TString;

begin

     json_nets := '"nets":[';

    try

       NetObjectIteratorHandle := Board.BoardIterator_Create;
       NetObjectIteratorHandle.AddFilter_ObjectSet(MkSet(eNetObject));
       NetObjectIteratorHandle.AddFilter_LayerSet(AllLayers);
       NetObjectIteratorHandle.AddFilter_Method(eProcessAll);

       Net := NetObjectIteratorHandle.FirstPCBObject;
        while (Net <> Nil) Do
        begin
            //ShowMessage(Track.Detail+' Layer '+IntToStr(Track.Layer)+' Pos '+FloatToStr(CoordToMMs(Track.X1)));


            json_nets:=json_nets+'"'+Net.Name+'",';

            Net := NetObjectIteratorHandle.NextPCBObject;

        end;

    finally
    end;

    json_nets :=removeLastComma(json_nets);
    json_nets := json_nets+']';

    Result := json_nets;
end;
