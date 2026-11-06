// Keep transport state local to one request; never persist or log credentials.
window.soundshareUpload = {
  send(url, token, contentType, body, onProgress) {
    const xhr = new XMLHttpRequest();
    const promise = new Promise((resolve, reject) => {
      xhr.open('POST', url);
      xhr.timeout = 90000;
      xhr.setRequestHeader('Authorization', 'Bearer ' + token);
      xhr.setRequestHeader('Content-Type', contentType);
      xhr.setRequestHeader('Accept', 'application/json');
      xhr.upload.onprogress = event => onProgress(event.loaded, event.lengthComputable ? event.total : body.byteLength);
      xhr.onload = () => resolve({ status: xhr.status, body: xhr.responseText });
      xhr.onerror = xhr.ontimeout = () => reject(new Error('UPLOAD_NETWORK'));
      xhr.onabort = () => reject(new Error('UPLOAD_CANCELLED'));
      xhr.send(body);
    });
    return { promise, abort: () => xhr.abort() };
  },
};
