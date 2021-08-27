import boto3

region = "us-east-1"

elb_listener_fh =  open("./web_lb_http_listener","r")
elb_listener_arn = elb_listener_fh.read()
elb_listener_fh.close()
web_lb_http_rule_http_tg_arn_fh = open("./web_lb_http_rule_http_tg","r")
web_lb_http_rule_http_tg_arn = web_lb_http_rule_http_tg_arn_fh.read()
web_lb_http_rule_http_tg_arn_fh.close()

web_lb_http_rule_http_fixed_response_arn_fh = open("./web_lb_http_rule_http_fixed_content","r")
web_lb_http_rule_http_fixed_response_arn = web_lb_http_rule_http_fixed_response_arn_fh.read()
web_lb_http_rule_http_fixed_response_arn_fh.close()

def lambda_tg(event, context):
    elb_client = boto3.client('elbv2', region_name=region)
    elb_client.set_rule_priorities(
        RulePriorities=[
            {
                'RuleArn': web_lb_http_rule_http_tg_arn,
                'Priority': 100
            },
            {
                'RuleArn': web_lb_http_rule_http_fixed_response_arn,
                'Priority': 200
            },
        ]
    )

def lambda_maintenance(event, context):
    elb_client = boto3.client('elbv2', region_name=region)
    elb_client.set_rule_priorities(
        RulePriorities=[
            {
                'RuleArn': web_lb_http_rule_http_tg_arn,
                'Priority': 200
            },
            {
                'RuleArn': web_lb_http_rule_http_fixed_response_arn,
                'Priority': 100
            },
        ]
    )
