window.addEventListener('load', () => {
  const getData = async () => {
    let dataObj;
    const response = await fetch(
      'https://jznexkn04k.execute-api.us-east-1.amazonaws.com/dev1/updateitem/',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      }
    );
    if (response.ok) {
      const data = await response.json();
      dataObj = data;
      const body = JSON.parse(dataObj['body']);
      const count = body['Attributes']['currentCount'];
      const counterDisplay = document.getElementById('counter');
      counterDisplay.innerHTML = `This document has been viewed ${count} times.`;
    } else {
      console.error(response.status);
    }
  };

  getData();
});
