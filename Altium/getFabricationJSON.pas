function getFabricationJSON(Board: IPCB_Board): TString;

var
    currentProject : IProject;
    BoardObjectIteratorHandle : IPCB_BoardIterator;
    Track                   : IPCB_Primitive;

    json_fabrication: TString;

begin

json_fabrication := '"fabrication":{"F":[],"B":[]}';

    Result := json_fabrication;
end;
