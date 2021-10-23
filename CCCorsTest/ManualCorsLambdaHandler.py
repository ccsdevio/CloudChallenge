import json

approved_sites = ['ccsportfolio.com', '\*.ccsportfolio.com'] 

def is_approved_site(url):
  return (url in approved_sites)

def lambda_handler(event, context):
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
