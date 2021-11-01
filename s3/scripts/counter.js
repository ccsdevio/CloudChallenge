window.addEventListener('load', () => {
  const getData = async () => {
    let dataObj;
    const response = await fetch(
      'https://4qwnf11vb6.execute-api.us-east-1.amazonaws.com/prod/api_resource/',
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
      const count = dataObj['body']['Attributes']['currentCount'];
      const counterDisplay = document.getElementById('counter');
      counterDisplay.innerHTML = `This document has been viewed ${count} times.`;
    } else {
      console.error(response.status);
    }
  };

  getData();
});
