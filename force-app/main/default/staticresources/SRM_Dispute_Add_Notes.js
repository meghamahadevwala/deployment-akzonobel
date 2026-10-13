//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	

	function onSubmitNote(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		var screenName = values['ggScreenName'];
		return new Promise(function(resolve, reject) {
			if(values && values['NoteBody'] ){
			//DataServiceWithName('WCM_SubmitAccountNote', values, false).then(result => {
			invoke({ 
				className: 'SRM_SubmitDisputeNoteData', 
				functionName: 'funcName',
				values: values 
			}).then(result => {
			
                if(result){
					//fireEvent(
					fireEvent(cmp.pageRef, 'updateLatestNote' , result.LatestNote);
					fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
					resolve(result);
						window.location.reload(true);
				} else{
					fireEvent(cmp.pageRef, 'updateLatestNote' , values.NoteBody);
					fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
					resolve(values);
						window.location.reload(true);
				}
					
            }).catch(error => {
                console.log('error :' + error);
				reject(error);
			});
		} else{
			resolve(values);
		}
		});
    }
    exports.onSubmitNote = onSubmitNote;
	
//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//
})));