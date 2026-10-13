//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	

	function onLoadDisputeDetail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, reject) {
			var screenName = values['ggScreenName'];
			invoke({ 
				className: 'DisputeDetailController', 
				functionName: 'onPageLoadFunction',
				values: values 
			}).then(result => {
				resolve(result);
            }).catch(error => {
                console.log('error :' + error);
				reject(error);
            });
		});
    }

	function saveDisputeNote(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'SRM_SubmitDisputeNoteData', 
				functionName: 'funcName',
				values: values 
			}).then(result => {
                if(result){
					//fireEvent(
					fireEvent(cmp.pageRef, 'updateLatestNote' , result.LatestNote);
					fireEvent(cmp.pageRef, 'closeScreen_' + result.ggScreenName , null);
					resolve(result);
				} else{
					fireEvent(cmp.pageRef, 'updateLatestNote' , values.NoteBody);
					fireEvent(cmp.pageRef, 'closeScreen_' + result.ggScreenName , null);
					resolve(values);
				}
					
            }).catch(error => {
                console.log('error :' + error);
				reject(error);
            });
		});
    }

	function ReloadDisputeDetailScreen() {
		return new Promise(function(resolve, reject) {
			setTimeout(() => {
				window.location.reload();
			}, 2000);
			
		});
    }
	
    exports.onLoadDisputeDetail = onLoadDisputeDetail;
	exports.saveDisputeNote = saveDisputeNote;
	exports.ReloadDisputeDetailScreen = ReloadDisputeDetailScreen;
	
//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//
})));