#!/usr/bin/env python3
"""
Compliance Checker Lambda Function

This function performs custom compliance checks beyond AWS Config rules:
1. Validates resource tagging compliance
2. Checks security group configurations
3. Validates S3 bucket policies
4. Monitors encryption status
5. Sends compliance reports via SNS
"""

import json
import boto3
import os
import logging
from datetime import datetime
from typing import Dict, List, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients - get region from environment or session
region = os.environ.get('AWS_REGION', boto3.Session().region_name)
config = boto3.client('config', region_name=region)
ec2 = boto3.client('ec2', region_name=region)
s3 = boto3.client('s3', region_name=region)
rds = boto3.client('rds', region_name=region)
securityhub = boto3.client('securityhub', region_name=region)
sns = boto3.client('sns', region_name=region)

# Environment variables
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'unknown')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'unknown')


def handler(event, context):
    """
    Main Lambda handler function
    """
    try:
        logger.info("Starting compliance validation")

        compliance_report = {
            'timestamp': datetime.now().isoformat(),
            'project': PROJECT_NAME,
            'environment': ENVIRONMENT,
            'config_rules_status': {},
            'custom_checks': {},
            'compliance_score': 0.0,
            'violations': [],
            'recommendations': []
        }

        # Get AWS Config rule compliance status
        compliance_report['config_rules_status'] = get_config_rules_compliance()

        # Perform custom compliance checks
        compliance_report['custom_checks'] = perform_custom_checks()

        # Calculate overall compliance score
        compliance_report['compliance_score'] = calculate_compliance_score(
            compliance_report['config_rules_status'],
            compliance_report['custom_checks']
        )

        # Generate recommendations
        compliance_report['recommendations'] = generate_recommendations(compliance_report)

        # Send notification if compliance score is below threshold
        if compliance_report['compliance_score'] < 90:  # 90% threshold
            send_compliance_notification(compliance_report)

        logger.info(f"Compliance check completed. Score: {compliance_report['compliance_score']:.1f}%")

        return {
            'statusCode': 200,
            'body': json.dumps(compliance_report)
        }

    except Exception as e:
        error_msg = f"Compliance check failed: {str(e)}"
        logger.error(error_msg)

        if SNS_TOPIC_ARN:
            send_error_notification(error_msg)

        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }


def get_config_rules_compliance() -> Dict[str, Any]:
    """
    Get compliance status for all Config rules
    """
    try:
        response = config.describe_compliance_by_config_rule()

        compliance_status = {
            'total_rules': 0,
            'compliant_rules': 0,
            'non_compliant_rules': 0,
            'rules_detail': {}
        }

        for rule_compliance in response.get('ComplianceByConfigRules', []):
            rule_name = rule_compliance['ConfigRuleName']
            compliance = rule_compliance['Compliance']

            compliance_status['total_rules'] += 1
            compliance_status['rules_detail'][rule_name] = {
                'status': compliance['ComplianceType'],
                'last_evaluated': compliance.get('ComplianceContributorCount', {})
            }

            if compliance['ComplianceType'] == 'COMPLIANT':
                compliance_status['compliant_rules'] += 1
            else:
                compliance_status['non_compliant_rules'] += 1

        logger.info(f"Config rules: {compliance_status['compliant_rules']}/{compliance_status['total_rules']} compliant")
        return compliance_status

    except Exception as e:
        logger.error(f"Failed to get Config rules compliance: {str(e)}")
        return {'total_rules': 0, 'compliant_rules': 0, 'non_compliant_rules': 0, 'rules_detail': {}}


def perform_custom_checks() -> Dict[str, Any]:
    """
    Perform custom compliance checks
    """
    custom_checks = {
        'tagging_compliance': check_resource_tagging(),
        'security_groups': check_security_groups(),
        's3_bucket_policies': check_s3_bucket_policies(),
        'encryption_status': check_encryption_compliance(),
        'public_access': check_public_access_compliance()
    }

    return custom_checks


def check_resource_tagging() -> Dict[str, Any]:
    """
    Check if resources have required tags
    """
    required_tags = ['Project', 'Environment', 'ManagedBy']
    tagging_report = {
        'total_resources': 0,
        'compliant_resources': 0,
        'violations': []
    }

    try:
        # Check EC2 instances
        ec2_response = ec2.describe_instances()
        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] in ['running', 'stopped']:
                    tagging_report['total_resources'] += 1
                    tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}

                    missing_tags = [tag for tag in required_tags if tag not in tags]
                    if not missing_tags:
                        tagging_report['compliant_resources'] += 1
                    else:
                        tagging_report['violations'].append({
                            'resource_type': 'EC2 Instance',
                            'resource_id': instance['InstanceId'],
                            'missing_tags': missing_tags
                        })

        # Check S3 buckets
        s3_response = s3.list_buckets()
        for bucket in s3_response['Buckets']:
            bucket_name = bucket['Name']
            if PROJECT_NAME in bucket_name:  # Only check project-related buckets
                tagging_report['total_resources'] += 1
                try:
                    tags_response = s3.get_bucket_tagging(Bucket=bucket_name)
                    tags = {tag['Key']: tag['Value'] for tag in tags_response.get('TagSet', [])}

                    missing_tags = [tag for tag in required_tags if tag not in tags]
                    if not missing_tags:
                        tagging_report['compliant_resources'] += 1
                    else:
                        tagging_report['violations'].append({
                            'resource_type': 'S3 Bucket',
                            'resource_id': bucket_name,
                            'missing_tags': missing_tags
                        })
                except s3.exceptions.NoSuchTagSet:
                    tagging_report['violations'].append({
                        'resource_type': 'S3 Bucket',
                        'resource_id': bucket_name,
                        'missing_tags': required_tags
                    })

        logger.info(f"Tagging compliance: {tagging_report['compliant_resources']}/{tagging_report['total_resources']} compliant")
        return tagging_report

    except Exception as e:
        logger.error(f"Failed to check resource tagging: {str(e)}")
        return {'total_resources': 0, 'compliant_resources': 0, 'violations': []}


def check_security_groups() -> Dict[str, Any]:
    """
    Check security group configurations for compliance
    """
    sg_report = {
        'total_security_groups': 0,
        'compliant_security_groups': 0,
        'violations': []
    }

    try:
        response = ec2.describe_security_groups()

        for sg in response['SecurityGroups']:
            if sg['GroupName'] == 'default':
                continue  # Skip default security groups

            sg_report['total_security_groups'] += 1
            violations = []

            # Check for overly permissive inbound rules
            for rule in sg['IpPermissions']:
                for ip_range in rule.get('IpRanges', []):
                    if ip_range.get('CidrIp') == '0.0.0.0/0':
                        # Allow only HTTP and HTTPS from anywhere
                        if rule.get('FromPort') not in [80, 443]:
                            violations.append({
                                'type': 'overly_permissive_inbound',
                                'port': rule.get('FromPort', 'all'),
                                'protocol': rule.get('IpProtocol', 'all'),
                                'cidr': '0.0.0.0/0'
                            })

            # Check for unused security groups
            # This is a simplified check - in practice, you'd need to check actual usage
            if not sg.get('IpPermissions') and not sg.get('IpPermissionsEgress'):
                violations.append({
                    'type': 'unused_security_group',
                    'group_id': sg['GroupId']
                })

            if not violations:
                sg_report['compliant_security_groups'] += 1
            else:
                sg_report['violations'].append({
                    'group_id': sg['GroupId'],
                    'group_name': sg['GroupName'],
                    'violations': violations
                })

        logger.info(f"Security groups: {sg_report['compliant_security_groups']}/{sg_report['total_security_groups']} compliant")
        return sg_report

    except Exception as e:
        logger.error(f"Failed to check security groups: {str(e)}")
        return {'total_security_groups': 0, 'compliant_security_groups': 0, 'violations': []}


def check_s3_bucket_policies() -> Dict[str, Any]:
    """
    Check S3 bucket policies for security compliance
    """
    s3_report = {
        'total_buckets': 0,
        'compliant_buckets': 0,
        'violations': []
    }

    try:
        response = s3.list_buckets()

        for bucket in response['Buckets']:
            bucket_name = bucket['Name']
            if PROJECT_NAME not in bucket_name:
                continue  # Only check project-related buckets

            s3_report['total_buckets'] += 1
            violations = []

            # Check public access block
            try:
                pab_response = s3.get_public_access_block(Bucket=bucket_name)
                pab_config = pab_response['PublicAccessBlockConfiguration']

                if not all([
                    pab_config.get('BlockPublicAcls', False),
                    pab_config.get('IgnorePublicAcls', False),
                    pab_config.get('BlockPublicPolicy', False),
                    pab_config.get('RestrictPublicBuckets', False)
                ]):
                    violations.append({
                        'type': 'public_access_not_blocked',
                        'current_config': pab_config
                    })
            except s3.exceptions.NoSuchPublicAccessBlockConfiguration:
                violations.append({
                    'type': 'no_public_access_block',
                    'message': 'Public access block not configured'
                })

            # Check bucket encryption
            try:
                encryption_response = s3.get_bucket_encryption(Bucket=bucket_name)
                # If we get here, encryption is enabled
            except s3.exceptions.ServerSideEncryptionConfigurationNotFoundError:
                violations.append({
                    'type': 'encryption_not_enabled',
                    'message': 'Server-side encryption not configured'
                })

            if not violations:
                s3_report['compliant_buckets'] += 1
            else:
                s3_report['violations'].append({
                    'bucket_name': bucket_name,
                    'violations': violations
                })

        logger.info(f"S3 buckets: {s3_report['compliant_buckets']}/{s3_report['total_buckets']} compliant")
        return s3_report

    except Exception as e:
        logger.error(f"Failed to check S3 bucket policies: {str(e)}")
        return {'total_buckets': 0, 'compliant_buckets': 0, 'violations': []}


def check_encryption_compliance() -> Dict[str, Any]:
    """
    Check encryption compliance across services
    """
    encryption_report = {
        'total_resources': 0,
        'encrypted_resources': 0,
        'violations': []
    }

    try:
        # Check RDS instances
        rds_response = rds.describe_db_instances()
        for db_instance in rds_response['DBInstances']:
            encryption_report['total_resources'] += 1

            if db_instance.get('StorageEncrypted', False):
                encryption_report['encrypted_resources'] += 1
            else:
                encryption_report['violations'].append({
                    'resource_type': 'RDS Instance',
                    'resource_id': db_instance['DBInstanceIdentifier'],
                    'issue': 'Storage not encrypted'
                })

        # Check EBS volumes
        ec2_response = ec2.describe_volumes()
        for volume in ec2_response['Volumes']:
            encryption_report['total_resources'] += 1

            if volume.get('Encrypted', False):
                encryption_report['encrypted_resources'] += 1
            else:
                encryption_report['violations'].append({
                    'resource_type': 'EBS Volume',
                    'resource_id': volume['VolumeId'],
                    'issue': 'Volume not encrypted'
                })

        logger.info(f"Encryption: {encryption_report['encrypted_resources']}/{encryption_report['total_resources']} encrypted")
        return encryption_report

    except Exception as e:
        logger.error(f"Failed to check encryption compliance: {str(e)}")
        return {'total_resources': 0, 'encrypted_resources': 0, 'violations': []}


def check_public_access_compliance() -> Dict[str, Any]:
    """
    Check for resources with unwanted public access
    """
    public_access_report = {
        'total_resources': 0,
        'private_resources': 0,
        'violations': []
    }

    try:
        # Check for RDS instances with public access
        rds_response = rds.describe_db_instances()
        for db_instance in rds_response['DBInstances']:
            public_access_report['total_resources'] += 1

            if not db_instance.get('PubliclyAccessible', False):
                public_access_report['private_resources'] += 1
            else:
                public_access_report['violations'].append({
                    'resource_type': 'RDS Instance',
                    'resource_id': db_instance['DBInstanceIdentifier'],
                    'issue': 'Database is publicly accessible'
                })

        # Check for EC2 instances with public IPs in private subnets
        ec2_response = ec2.describe_instances()
        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] in ['running']:
                    public_access_report['total_resources'] += 1

                    # Check if instance has public IP but is tagged as private
                    tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    subnet_type = tags.get('SubnetType', '').lower()

                    if (instance.get('PublicIpAddress') and
                        subnet_type in ['private', 'database']):
                        public_access_report['violations'].append({
                            'resource_type': 'EC2 Instance',
                            'resource_id': instance['InstanceId'],
                            'issue': f'Public IP in {subnet_type} subnet'
                        })
                    else:
                        public_access_report['private_resources'] += 1

        logger.info(f"Public access: {public_access_report['private_resources']}/{public_access_report['total_resources']} properly private")
        return public_access_report

    except Exception as e:
        logger.error(f"Failed to check public access compliance: {str(e)}")
        return {'total_resources': 0, 'private_resources': 0, 'violations': []}


def calculate_compliance_score(config_status: Dict, custom_checks: Dict) -> float:
    """
    Calculate overall compliance score
    """
    try:
        total_score = 0.0
        total_weight = 0.0

        # Config rules compliance (40% weight)
        if config_status.get('total_rules', 0) > 0:
            config_score = (config_status['compliant_rules'] / config_status['total_rules']) * 100
            total_score += config_score * 0.4
            total_weight += 0.4

        # Custom checks (60% weight total, divided among checks)
        check_weights = {
            'tagging_compliance': 0.15,
            'security_groups': 0.15,
            's3_bucket_policies': 0.15,
            'encryption_status': 0.10,
            'public_access': 0.05
        }

        for check_name, weight in check_weights.items():
            check_data = custom_checks.get(check_name, {})
            total_resources = check_data.get('total_resources', 0) or check_data.get('total_buckets', 0) or check_data.get('total_security_groups', 0)
            compliant_resources = check_data.get('compliant_resources', 0) or check_data.get('compliant_buckets', 0) or check_data.get('compliant_security_groups', 0) or check_data.get('encrypted_resources', 0) or check_data.get('private_resources', 0)

            if total_resources > 0:
                check_score = (compliant_resources / total_resources) * 100
                total_score += check_score * weight
                total_weight += weight

        if total_weight > 0:
            return total_score / total_weight
        else:
            return 0.0

    except Exception as e:
        logger.error(f"Failed to calculate compliance score: {str(e)}")
        return 0.0


def generate_recommendations(compliance_report: Dict) -> List[str]:
    """
    Generate recommendations based on compliance findings
    """
    recommendations = []

    # Config rules recommendations
    config_status = compliance_report.get('config_rules_status', {})
    if config_status.get('non_compliant_rules', 0) > 0:
        recommendations.append("Review and remediate non-compliant AWS Config rules")

    # Custom checks recommendations
    custom_checks = compliance_report.get('custom_checks', {})

    if custom_checks.get('tagging_compliance', {}).get('violations'):
        recommendations.append("Apply required tags (Project, Environment, ManagedBy) to all resources")

    if custom_checks.get('security_groups', {}).get('violations'):
        recommendations.append("Review security group rules and remove overly permissive access")

    if custom_checks.get('s3_bucket_policies', {}).get('violations'):
        recommendations.append("Enable S3 public access block and server-side encryption")

    if custom_checks.get('encryption_status', {}).get('violations'):
        recommendations.append("Enable encryption for RDS instances and EBS volumes")

    if custom_checks.get('public_access', {}).get('violations'):
        recommendations.append("Remove public access from resources in private subnets")

    return recommendations


def send_compliance_notification(compliance_report: Dict) -> None:
    """
    Send SNS notification with compliance report
    """
    if not SNS_TOPIC_ARN:
        return

    try:
        score = compliance_report['compliance_score']
        subject = f"🔍 Compliance Report - {PROJECT_NAME} {ENVIRONMENT} - {score:.1f}% Score"

        if score < 70:
            subject = f"🚨 {subject} - Critical"
        elif score < 90:
            subject = f"⚠️ {subject} - Warning"
        else:
            subject = f"✅ {subject} - Good"

        message = f"""
Compliance Report
================

Project: {PROJECT_NAME}
Environment: {ENVIRONMENT}
Compliance Score: {score:.1f}%
Report Date: {compliance_report['timestamp']}

📊 CONFIG RULES STATUS:
{format_config_status(compliance_report['config_rules_status'])}

🔍 CUSTOM CHECKS:
{format_custom_checks(compliance_report['custom_checks'])}

💡 RECOMMENDATIONS:
{format_recommendations(compliance_report['recommendations'])}

🔗 NEXT STEPS:
1. Review detailed findings in AWS Console
2. Address high-priority violations first
3. Implement recommended security controls
4. Schedule regular compliance reviews

Generated by EPiC Compliance Monitor
        """

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )

        logger.info("Compliance notification sent successfully")

    except Exception as e:
        logger.error(f"Failed to send notification: {str(e)}")


def format_config_status(config_status: Dict) -> str:
    """Format Config rules status for notification"""
    if not config_status.get('total_rules'):
        return "  No Config rules found"

    return f"  Compliant: {config_status['compliant_rules']}/{config_status['total_rules']} rules"


def format_custom_checks(custom_checks: Dict) -> str:
    """Format custom checks for notification"""
    if not custom_checks:
        return "  No custom checks performed"

    formatted = []
    for check_name, check_data in custom_checks.items():
        total = check_data.get('total_resources', 0) or check_data.get('total_buckets', 0) or check_data.get('total_security_groups', 0)
        compliant = (check_data.get('compliant_resources', 0) or
                    check_data.get('compliant_buckets', 0) or
                    check_data.get('compliant_security_groups', 0) or
                    check_data.get('encrypted_resources', 0) or
                    check_data.get('private_resources', 0))

        check_display = check_name.replace('_', ' ').title()
        formatted.append(f"  • {check_display}: {compliant}/{total}")

    return "\n".join(formatted)


def format_recommendations(recommendations: List[str]) -> str:
    """Format recommendations for notification"""
    if not recommendations:
        return "  No specific recommendations at this time"

    return "\n".join(f"  • {rec}" for rec in recommendations)


def send_error_notification(error_message: str) -> None:
    """Send error notification"""
    if not SNS_TOPIC_ARN:
        return

    try:
        subject = f"🚨 Compliance Check Failed - {PROJECT_NAME} {ENVIRONMENT}"
        message = f"""
Compliance Check Failed
======================

Project: {PROJECT_NAME}
Environment: {ENVIRONMENT}
Error Time: {datetime.now().isoformat()}

Error: {error_message}

Please check the CloudWatch logs for more details.
        """

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )

    except Exception as e:
        logger.error(f"Failed to send error notification: {str(e)}")