clearlistener()
try (destroyDialog VertexAnimationExporter) catch()
rollout VertexAnimationExporter "Vertex Animation exporter" width:460 height:520 (

    fn objFilter obj = (
        return true;
    )

    group  "Mesh (.obj) "  (
        button btn_objoutput "Select .obj file" tooltip: "Output .obj file. Recommended to save it NOT on Asset folder"   width:440  ;
    )
    
     group  "Point Cache (.pc2) "  (
        button btn_pcOutput "Select .pc2 file" tooltip: "Output .pc2 file. Recommended to save it NOT on Asset folder"   width:440  ;
    )
    
    group  "Mesh Sequence (.obj)"  (
        button btn_sequenceOutput "Select .obj file" tooltip: "Output .obj file. Frames will be saved  as separate obj files with given name plus frame index. Recommended to save it NOT on Asset folder"   width:440  ;
    )
     
 

   
    group  "Topology"  (
        radiobuttons rb_topologytype labels:#(  "quad", "polygons" ) default:2;
    )
    
    group  "Time configuration"  (
         spinner spn_start "Start:" range:[-1e+006,1e+006,animationRange.start] type:#integer across: 2;
         spinner spn_end "End:" range:[-1e+006,1e+006,animationRange.end] type:#integer across: 2;
    )
    
    group  "Export"  (
        button btn_exportObj "Export Mesh" tooltip: "Export mesh"   width:130  across: 3;
        button btn_exportPC "Export Point Cache" tooltip: "Export point cache"   width:130  across: 3;
        button btn_exportSequence "Export Mesh Sequence" tooltip: "Export mesh sequence"   width:130  across: 3;
    )
    
    group  "Progress"  (
        progressBar  pb "Progress"  value:0  color:Blue  orient:#horizontal
    )
  
    label lbl "Designed for use with"  across:2   offset:[34,0]; 
    hyperLink  hl "Vertex Animation Tools" address: "http://u3d.as/1iJP" align:#center  color: (color 88 144 225) hoverColor:  (color 88 144 225) across:2  offset:[-66,0]; 
    hyperLink  hl1 "Polyflow Studio 2019" address: "http://polyflow.studio" align:#center  color: (color 88 144 225) hoverColor: (color 88 144 225);
     
   local outputPCFileName = undefined;   
   local outputObjFileName = undefined;      
   local outputSequenceFileName = undefined; 
    
    local vertCount = case classof selection[1] of (
        Editable_Poly: getNumVerts selection[1]
        Editable_Mesh: selection[1].numVerts
    )

 
    on btn_objoutput pressed do (
        f = getSaveFileName caption:"Select output obj file:"  types:"  obj|*.obj|" historyCategory:"objfiles"
        if f != undefined then (
            btn_objoutput.caption = "file:  "+f;
            outputObjFileName = f;
        ) else (
              btn_objoutput.caption = "select .obj file";
             outputObjFileName = undefined;
        )
    )
    
    on btn_sequenceOutput pressed do (
        f = getSaveFileName caption:"Select output obj file:"  types:"  obj|*.obj|" historyCategory:"objfiles"
        if f != undefined then (
            btn_sequenceOutput.caption = "file:  "+f;
            outputSequenceFileName = f;
        ) else (
              btn_sequenceOutput.caption = "select .obj file";
             outputSequenceFileName = undefined;
        )
    )
    
    on btn_pcoutput pressed do (
        f = getSaveFileName caption:"Select output obj file:"  types:"  pc2|*.pc2|" historyCategory:"pc2files"
        if f != undefined then (
            btn_pcoutput.caption = "file:  "+f;
            outputPCFileName = f;
        ) else (
            btn_pcoutput.caption  = "Select .pc2 file";
            outputPCFileName = undefined;
        )
    )
 

    fn InitObjExport = (
        theINI = objExp.getIniName()
        setIniSetting theINI "General" "Preset" "<NONE>";         
        setIniSetting theINI "Geometry" "FlipZyAxis" "0";
        if rb_topologytype.state == 2 then ( 
            setIniSetting theINI "Geometry" "FaceType" "2";
            print "Set Face type 2";
        )
        if rb_topologytype == 1 then ( 
            setIniSetting theINI "Geometry" "FaceType" "1";
            print "Set Face type 1";
        )
        setIniSetting theINI "Geometry" "Shapes" "0";        
        setIniSetting theINI "Geometry" "SmoothingGroups" "1";
        setIniSetting theINI "Geometry" "TextureCoords" "1";
        setIniSetting theINI "Geometry" "normals" "0";
        setIniSetting theINI "Geometry" "ObjScale" "1.000";        
        setIniSetting theINI "Optimize" "optVertex" "0";
        setIniSetting theINI "Optimize" "optNormals" "0";
        setIniSetting theINI "Optimize" "optTextureCoords" "0";        
        setIniSetting theINI "Material" "UseMaterial" "1";
        setIniSetting theINI "Material" "CreateMatLibrary" "0";
        setIniSetting theINI "Material" "MapChannel" "1";        
        setIniSetting theINI "Output" "RelativeIndex" "0";
        setIniSetting theINI "Output" "Target" "0";
        setIniSetting theINI "Output" "Precision" "5";
        return 1;
    )
    
    on btn_exportPC pressed do (
       if  outputPcFileName == undefined  do (
            messageBox "Please select .pc file";
            return 0;
        ) 
            
        initialSlidertime = spn_start.value;    
        totalFrames =  (spn_end.value  - spn_start.value)+1;
        
        --if rb_objectsype.state == 2 then (
        if selection.count != 1 do (
            messageBox "Please select only one object";
            return 0;
        )
        --)
        objectToOutput = selection[1];
        
        --print (tot);
        slidertime = initialSlidertime;
        --tm = inverse objectToOutput.transform;
        tmesh = snapshotAsMesh objectToOutput;
        vertsCount = tmesh.numverts;
        _file = fopen outputPCFileName "wb";
        WriteString  _file "POINTCACHE2";
        WriteLong _file 1; --INT VERSION 
        WriteLong _file vertsCount; --INT VERTCOUNT
        WriteFloat _file 0; --FLOAT START FRAME
        WriteFloat _file 1; --FLOAT SAMPLE RATE
        WriteLong _file totalFrames ; --FRAMES COUNT  
        
        for t = 1 to totalFrames do (
                tmesh = snapshotAsMesh objectToOutput;
                 
                if vertsCount !=  tmesh.numverts then (
                    messageBox  "Seems like you try to export Point Cache for mesh with dynamic topology. This not allowed. Please use Export Mesh Sequence instead." ; 
                    fclose _file;
                    pb.value = 0;
                    return 0;
                )          
            
                for v = 1 to vertsCount do (
                    vert = getVert tmesh v;
 
                    WriteFloat _file vert.x;
                    WriteFloat _file vert.y;
                    WriteFloat _file vert.z;
                )
                slidertime +=1;
                pb.value = ((t as float)/(totalFrames as float)) * 100.0;   
        )
        slidertime = initialSlidertime;
        fclose _file;
        messageBox ( "Point Cache "+ objectToOutput.name+ " "  + (vertsCount as string) +"  vertices "+ (totalFrames as string)+" frames exported" ) ; 
        pb.value = 0;
    )
    
    on btn_exportObj pressed do(
        InitObjExport(); 
        if  outputObjFileName == undefined  do (
            messageBox "Please select .obj file";
            return 0;
        )
        
        --if rb_objectsype.state == 2 then (
        if selection.count == 0 do (
            messageBox "Please select only one object";
            return 0;
        )
        --select objectToOutput;
        --)
        exportFile outputObjFileName #noPrompt selectedOnly:True;
    )

    on btn_exportSequence pressed do (
        InitObjExport(); 
        if  outputSequenceFileName == undefined  do (
            messageBox "Please select .obj file";
            return 0;
        )
        
         if selection.count == 0 do (
            if objectToOutput == undefined do (
                 messageBox "Please select objects";
                 return 0;
            )
            select objectToOutput;
        )
      
        
        initialSlidertime = spn_start.value;    
        totalFrames =  (spn_end.value  - spn_start.value);
        slidertime = initialSlidertime;
        nameBase = (getFilenamePath outputSequenceFileName) + (getFilenameFile outputSequenceFileName);
        
        for t = 0 to totalFrames do (
                --select objectToOutput;
                fname = nameBase+(t as string)+".obj";
                exportFile fname #noPrompt selectedOnly:True
                slidertime +=1;
                pb.value = ((t as float)/(totalFrames as float)) * 100.0;   
        )
        slidertime = initialSlidertime;
        pb.value = 0;
    )

)


 
createDialog VertexAnimationExporter 460 386 style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
