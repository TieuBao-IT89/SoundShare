const assert=require('node:assert/strict');
const {readFile}=require('node:fs/promises');
const path=require('node:path');
const vm=require('node:vm');
const test=require('node:test');
async function fixture(){
  let xhr;
  class Request{
    constructor(){xhr=this;this.upload={};this.headers={};}
    open(method,url){this.method=method;this.url=url;}
    setRequestHeader(name,value){this.headers[name]=value;}
    send(body){this.body=body;}
    abort(){this.aborted=true;this.onabort();}
  }
  const window={};vm.runInNewContext(await readFile(path.join(__dirname,'../../web/upload-transport.js'),'utf8'),{window,XMLHttpRequest:Request});
  const progress=[];
  const handle=window.soundshareUpload.send('/api/v1/uploads/audio','fixture-token','multipart/form-data; boundary=fixture',new Uint8Array([1,2,3]),(loaded,total)=>progress.push([loaded,total]));
  return {handle,xhr,progress};
}
test('Web upload uses actual transport progress and waits for the server response',async()=>{
  const {handle,xhr,progress}=await fixture();let done=false;handle.promise.then(()=>done=true);
  xhr.upload.onprogress({loaded:2,total:3,lengthComputable:true});
  xhr.upload.onprogress({loaded:3,total:3,lengthComputable:true});await Promise.resolve();
  assert.equal(done,false);assert.deepEqual(progress,[[2,3],[3,3]]);
  assert.equal(xhr.headers.Authorization,'Bearer fixture-token');assert.equal(xhr.method,'POST');
  xhr.status=201;xhr.responseText='{"success":true,"data":{"id":"fixture"}}';xhr.onload();
  const response=await handle.promise;assert.equal(response.status,201);assert.equal(JSON.parse(response.body).data.id,'fixture');
});
test('Cancel aborts the transport and never resolves as a saved upload',async()=>{
  const {handle,xhr}=await fixture();const rejected=assert.rejects(handle.promise,/UPLOAD_CANCELLED/);handle.abort();await rejected;assert.equal(xhr.aborted,true);
});
test('Network failures reject rather than simulate upload success',async()=>{
  const {handle,xhr}=await fixture();const rejected=assert.rejects(handle.promise,/UPLOAD_NETWORK/);xhr.onerror();await rejected;
});
