#!/usr/bin/env python3
"""
Cost Optimization Lambda Function

This function analyzes AWS resource usage and provides cost optimization recommendations:
1. Identifies underutilized EC2 instances
2. Analyzes S3 storage patterns
3. Reviews RDS instance utilization
4. Suggests Reserved Instance purchases
5. Recommends right-sizing opportunities
"""

import json
import boto3
import os
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients - get region from environment or session
region = os.environ.get('AWS_REGION', boto3.Session().region_name)
ce = boto3.client('ce', region_name=region)
ec2 = boto3.client('ec2', region_name=region)
cloudwatch = boto3.client('cloudwatch', region_name=region)
rds = boto3.client('rds', region_name=region)
s3 = boto3.client('s3', region_name=region)
sns = boto3.client('sns', region_name=region)

# Environment variables
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'unknown')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'unknown')
COST_THRESHOLD = float(os.environ.get('COST_THRESHOLD', '10.0'))
UTILIZATION_THRESHOLD = float(os.environ.get('UTILIZATION_THRESHOLD', '20.0'))


def handler(event, context):
    """
    Main Lambda handler function
    """
    try:
        logger.info("Starting cost optimization analysis")

        recommendations = {
            'timestamp': datetime.now().isoformat(),
            'project': PROJECT_NAME,
            'environment': ENVIRONMENT,
            'ec2_recommendations': [],
            'rds_recommendations': [],
            's3_recommendations': [],
            'reserved_instance_recommendations': [],
            'cost_summary': {},
            'total_potential_savings': 0.0
        }

        # Get current cost data
        recommendations['cost_summary'] = get_cost_summary()

        # Analyze EC2 instances
        ec2_recommendations = analyze_ec2_instances()
        recommendations['ec2_recommendations'] = ec2_recommendations

        # Analyze RDS instances
        rds_recommendations = analyze_rds_instances()
        recommendations['rds_recommendations'] = rds_recommendations

        # Analyze S3 storage
        s3_recommendations = analyze_s3_storage()
        recommendations['s3_recommendations'] = s3_recommendations

        # Get Reserved Instance recommendations
        ri_recommendations = get_reserved_instance_recommendations()
        recommendations['reserved_instance_recommendations'] = ri_recommendations

        # Calculate total potential savings
        total_savings = sum([
            sum(rec.get('monthly_savings', 0) for rec in ec2_recommendations),
            sum(rec.get('monthly_savings', 0) for rec in rds_recommendations),
            sum(rec.get('monthly_savings', 0) for rec in s3_recommendations),
            sum(rec.get('monthly_savings', 0) for rec in ri_recommendations)
        ])
        recommendations['total_potential_savings'] = total_savings

        # Send notification if significant savings are possible
        if total_savings > COST_THRESHOLD:
            send_recommendations_notification(recommendations)

        logger.info(f"Cost optimization analysis completed. Potential savings: ${total_savings:.2f}/month")

        return {
            'statusCode': 200,
            'body': json.dumps(recommendations)
        }

    except Exception as e:
        error_msg = f"Cost optimization analysis failed: {str(e)}"
        logger.error(error_msg)

        if SNS_TOPIC_ARN:
            send_error_notification(error_msg)

        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }


def get_cost_summary() -> Dict[str, Any]:
    """
    Get current month cost summary
    """
    try:
        end_date = datetime.now().strftime('%Y-%m-%d')
        start_date = datetime.now().replace(day=1).strftime('%Y-%m-%d')

        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='MONTHLY',
            Metrics=['BlendedCost'],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'SERVICE'}
            ]
        )

        cost_summary = {
            'current_month_total': 0.0,
            'by_service': {}
        }

        if response['ResultsByTime']:
            for group in response['ResultsByTime'][0]['Groups']:
                service = group['Keys'][0]
                amount = float(group['Metrics']['BlendedCost']['Amount'])
                cost_summary['by_service'][service] = amount
                cost_summary['current_month_total'] += amount

        logger.info(f"Current month cost: ${cost_summary['current_month_total']:.2f}")
        return cost_summary

    except Exception as e:
        logger.error(f"Failed to get cost summary: {str(e)}")
        return {'current_month_total': 0.0, 'by_service': {}}


def analyze_ec2_instances() -> List[Dict[str, Any]]:
    """
    Analyze EC2 instances for optimization opportunities
    """
    recommendations = []

    try:
        # Get all running instances
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'instance-state-name', 'Values': ['running']},
                {'Name': 'tag:Project', 'Values': [PROJECT_NAME]}
            ]
        )

        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_type = instance['InstanceType']

                # Get CPU utilization for the past 7 days
                cpu_utilization = get_average_cpu_utilization(instance_id)

                if cpu_utilization < UTILIZATION_THRESHOLD:
                    # Suggest downsizing
                    suggested_type = suggest_smaller_instance_type(instance_type)
                    if suggested_type:
                        monthly_savings = estimate_instance_cost_savings(instance_type, suggested_type)
                        recommendations.append({
                            'instance_id': instance_id,
                            'current_type': instance_type,
                            'suggested_type': suggested_type,
                            'current_cpu_utilization': cpu_utilization,
                            'monthly_savings': monthly_savings,
                            'recommendation': f'Downsize from {instance_type} to {suggested_type}',
                            'reason': f'CPU utilization is only {cpu_utilization:.1f}%'
                        })

        logger.info(f"Found {len(recommendations)} EC2 optimization opportunities")
        return recommendations

    except Exception as e:
        logger.error(f"Failed to analyze EC2 instances: {str(e)}")
        return []


def analyze_rds_instances() -> List[Dict[str, Any]]:
    """
    Analyze RDS instances for optimization opportunities
    """
    recommendations = []

    try:
        response = rds.describe_db_instances()

        for db_instance in response['DBInstances']:
            if db_instance['DBInstanceStatus'] != 'available':
                continue

            instance_id = db_instance['DBInstanceIdentifier']
            instance_class = db_instance['DBInstanceClass']

            # Get CPU and connection utilization
            cpu_utilization = get_rds_cpu_utilization(instance_id)
            connection_utilization = get_rds_connection_utilization(instance_id, db_instance.get('AllocatedStorage', 0))

            if cpu_utilization < UTILIZATION_THRESHOLD and connection_utilization < 50:
                # Suggest downsizing
                suggested_class = suggest_smaller_rds_class(instance_class)
                if suggested_class:
                    monthly_savings = estimate_rds_cost_savings(instance_class, suggested_class)
                    recommendations.append({
                        'instance_id': instance_id,
                        'current_class': instance_class,
                        'suggested_class': suggested_class,
                        'current_cpu_utilization': cpu_utilization,
                        'connection_utilization': connection_utilization,
                        'monthly_savings': monthly_savings,
                        'recommendation': f'Downsize from {instance_class} to {suggested_class}',
                        'reason': f'CPU utilization is {cpu_utilization:.1f}% and connections are {connection_utilization:.1f}% utilized'
                    })

        logger.info(f"Found {len(recommendations)} RDS optimization opportunities")
        return recommendations

    except Exception as e:
        logger.error(f"Failed to analyze RDS instances: {str(e)}")
        return []


def analyze_s3_storage() -> List[Dict[str, Any]]:
    """
    Analyze S3 storage for optimization opportunities
    """
    recommendations = []

    try:
        response = s3.list_buckets()

        for bucket in response['Buckets']:
            bucket_name = bucket['Name']

            # Skip buckets not related to this project
            if PROJECT_NAME not in bucket_name:
                continue

            # Check lifecycle policies
            lifecycle_policy = get_bucket_lifecycle_policy(bucket_name)
            storage_analysis = analyze_bucket_storage(bucket_name)

            if not lifecycle_policy and storage_analysis['total_size_gb'] > 1:
                monthly_savings = estimate_s3_lifecycle_savings(storage_analysis)
                recommendations.append({
                    'bucket_name': bucket_name,
                    'current_storage_gb': storage_analysis['total_size_gb'],
                    'old_objects_count': storage_analysis['old_objects_count'],
                    'monthly_savings': monthly_savings,
                    'recommendation': 'Implement lifecycle policy',
                    'reason': f'Bucket has {storage_analysis["old_objects_count"]} objects older than 30 days without lifecycle policy'
                })

        logger.info(f"Found {len(recommendations)} S3 optimization opportunities")
        return recommendations

    except Exception as e:
        logger.error(f"Failed to analyze S3 storage: {str(e)}")
        return []


def get_reserved_instance_recommendations() -> List[Dict[str, Any]]:
    """
    Get Reserved Instance purchase recommendations from AWS Cost Explorer
    """
    try:
        response = ce.get_reservation_purchase_recommendation(
            Service='Amazon Elastic Compute Cloud - Compute',
            PaymentOption='PARTIAL_UPFRONT',
            TermInYears='ONE_YEAR',
            LookbackPeriodInDays='SIXTY_DAYS'
        )

        recommendations = []
        for recommendation in response.get('Recommendations', []):
            details = recommendation.get('RecommendationDetails', {})
            recommendations.append({
                'instance_type': details.get('InstanceDetails', {}).get('EC2InstanceDetails', {}).get('InstanceType'),
                'recommended_instances': details.get('RecommendedNumberOfInstancesToPurchase'),
                'monthly_savings': float(details.get('EstimatedMonthlySavingsAmount', 0)),
                'upfront_cost': float(details.get('UpfrontCost', 0)),
                'recommendation': 'Purchase Reserved Instances',
                'reason': f"Could save ${details.get('EstimatedMonthlySavingsAmount', 0)}/month"
            })

        return recommendations

    except Exception as e:
        logger.error(f"Failed to get Reserved Instance recommendations: {str(e)}")
        return []


def get_average_cpu_utilization(instance_id: str) -> float:
    """
    Get average CPU utilization for an EC2 instance over the past 7 days
    """
    try:
        end_time = datetime.now()
        start_time = end_time - timedelta(days=7)

        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[
                {'Name': 'InstanceId', 'Value': instance_id}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,  # 1 hour
            Statistics=['Average']
        )

        if response['Datapoints']:
            avg_cpu = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
            return avg_cpu

        return 0.0

    except Exception as e:
        logger.error(f"Failed to get CPU utilization for {instance_id}: {str(e)}")
        return 0.0


def get_rds_cpu_utilization(instance_id: str) -> float:
    """
    Get average CPU utilization for an RDS instance
    """
    try:
        end_time = datetime.now()
        start_time = end_time - timedelta(days=7)

        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/RDS',
            MetricName='CPUUtilization',
            Dimensions=[
                {'Name': 'DBInstanceIdentifier', 'Value': instance_id}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Average']
        )

        if response['Datapoints']:
            avg_cpu = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
            return avg_cpu

        return 0.0

    except Exception as e:
        logger.error(f"Failed to get RDS CPU utilization for {instance_id}: {str(e)}")
        return 0.0


def get_rds_connection_utilization(instance_id: str, max_connections: int) -> float:
    """
    Get connection utilization for an RDS instance
    """
    try:
        end_time = datetime.now()
        start_time = end_time - timedelta(days=7)

        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/RDS',
            MetricName='DatabaseConnections',
            Dimensions=[
                {'Name': 'DBInstanceIdentifier', 'Value': instance_id}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Average']
        )

        if response['Datapoints'] and max_connections > 0:
            avg_connections = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
            return (avg_connections / max_connections) * 100

        return 0.0

    except Exception as e:
        logger.error(f"Failed to get RDS connection utilization for {instance_id}: {str(e)}")
        return 0.0


def suggest_smaller_instance_type(current_type: str) -> Optional[str]:
    """
    Suggest a smaller instance type for cost optimization
    """
    # Simple mapping for common downsizing scenarios
    downsize_map = {
        't3.large': 't3.medium',
        't3.medium': 't3.small',
        't3.xlarge': 't3.large',
        'm5.large': 'm5.medium',
        'm5.xlarge': 'm5.large',
        'm5.2xlarge': 'm5.xlarge',
        'r5.large': 'r5.medium',
        'r5.xlarge': 'r5.large',
        'c5.large': 'c5.medium',
        'c5.xlarge': 'c5.large'
    }

    return downsize_map.get(current_type)


def suggest_smaller_rds_class(current_class: str) -> Optional[str]:
    """
    Suggest a smaller RDS instance class
    """
    downsize_map = {
        'db.t3.large': 'db.t3.medium',
        'db.t3.medium': 'db.t3.small',
        'db.m5.large': 'db.m5.medium',
        'db.m5.xlarge': 'db.m5.large',
        'db.r5.large': 'db.r5.medium',
        'db.r5.xlarge': 'db.r5.large'
    }

    return downsize_map.get(current_class)


def estimate_instance_cost_savings(current_type: str, suggested_type: str) -> float:
    """
    Estimate monthly cost savings from instance downsizing
    """
    # Simplified cost estimation (would need actual pricing data for accuracy)
    cost_map = {
        't3.nano': 5, 't3.micro': 8, 't3.small': 17, 't3.medium': 34, 't3.large': 67,
        'm5.medium': 44, 'm5.large': 87, 'm5.xlarge': 174,
        'r5.medium': 61, 'r5.large': 122, 'r5.xlarge': 244,
        'c5.medium': 39, 'c5.large': 77, 'c5.xlarge': 154
    }

    current_cost = cost_map.get(current_type, 0)
    suggested_cost = cost_map.get(suggested_type, 0)

    return max(0, current_cost - suggested_cost)


def estimate_rds_cost_savings(current_class: str, suggested_class: str) -> float:
    """
    Estimate monthly cost savings from RDS downsizing
    """
    # Simplified RDS cost estimation
    cost_map = {
        'db.t3.micro': 15, 'db.t3.small': 30, 'db.t3.medium': 61, 'db.t3.large': 122,
        'db.m5.medium': 70, 'db.m5.large': 140, 'db.m5.xlarge': 280,
        'db.r5.medium': 85, 'db.r5.large': 170, 'db.r5.xlarge': 340
    }

    current_cost = cost_map.get(current_class, 0)
    suggested_cost = cost_map.get(suggested_class, 0)

    return max(0, current_cost - suggested_cost)


def get_bucket_lifecycle_policy(bucket_name: str) -> Optional[Dict]:
    """
    Check if bucket has lifecycle policy
    """
    try:
        response = s3.get_bucket_lifecycle_configuration(Bucket=bucket_name)
        return response.get('Rules', [])
    except s3.exceptions.NoSuchLifecycleConfiguration:
        return None
    except Exception as e:
        logger.error(f"Failed to get lifecycle policy for {bucket_name}: {str(e)}")
        return None


def analyze_bucket_storage(bucket_name: str) -> Dict[str, Any]:
    """
    Analyze bucket storage patterns
    """
    try:
        # This is a simplified analysis - in practice, you'd use S3 analytics
        response = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000)

        total_size = 0
        old_objects_count = 0
        cutoff_date = datetime.now() - timedelta(days=30)

        for obj in response.get('Contents', []):
            total_size += obj['Size']
            if obj['LastModified'].replace(tzinfo=None) < cutoff_date:
                old_objects_count += 1

        return {
            'total_size_gb': total_size / (1024**3),
            'old_objects_count': old_objects_count
        }

    except Exception as e:
        logger.error(f"Failed to analyze storage for {bucket_name}: {str(e)}")
        return {'total_size_gb': 0, 'old_objects_count': 0}


def estimate_s3_lifecycle_savings(storage_analysis: Dict[str, Any]) -> float:
    """
    Estimate savings from implementing S3 lifecycle policies
    """
    # Estimate 40% of old objects could move to IA, 30% to Glacier
    standard_cost_per_gb = 0.023  # Standard storage cost per GB/month
    ia_cost_per_gb = 0.0125      # IA storage cost per GB/month
    glacier_cost_per_gb = 0.004  # Glacier cost per GB/month

    old_data_gb = storage_analysis['total_size_gb'] * 0.7  # Assume 70% is old data
    ia_savings = old_data_gb * 0.4 * (standard_cost_per_gb - ia_cost_per_gb)
    glacier_savings = old_data_gb * 0.3 * (standard_cost_per_gb - glacier_cost_per_gb)

    return ia_savings + glacier_savings


def send_recommendations_notification(recommendations: Dict[str, Any]) -> None:
    """
    Send SNS notification with cost optimization recommendations
    """
    if not SNS_TOPIC_ARN:
        return

    try:
        total_savings = recommendations['total_potential_savings']
        subject = f"💰 Cost Optimization Report - {PROJECT_NAME} {ENVIRONMENT} - ${total_savings:.2f}/month savings"

        message = f"""
Cost Optimization Report
========================

Project: {PROJECT_NAME}
Environment: {ENVIRONMENT}
Analysis Date: {recommendations['timestamp']}

💰 POTENTIAL MONTHLY SAVINGS: ${total_savings:.2f}

📊 CURRENT COSTS:
Total This Month: ${recommendations['cost_summary']['current_month_total']:.2f}

🖥️ EC2 RECOMMENDATIONS ({len(recommendations['ec2_recommendations'])}):
{format_ec2_recommendations(recommendations['ec2_recommendations'])}

🗄️ RDS RECOMMENDATIONS ({len(recommendations['rds_recommendations'])}):
{format_rds_recommendations(recommendations['rds_recommendations'])}

📦 S3 RECOMMENDATIONS ({len(recommendations['s3_recommendations'])}):
{format_s3_recommendations(recommendations['s3_recommendations'])}

💎 RESERVED INSTANCE OPPORTUNITIES ({len(recommendations['reserved_instance_recommendations'])}):
{format_ri_recommendations(recommendations['reserved_instance_recommendations'])}

⚡ NEXT STEPS:
1. Review recommendations in AWS Console
2. Test downsizing in non-production environments first
3. Consider Reserved Instance purchases for stable workloads
4. Implement S3 lifecycle policies for old data

Generated by EPiC Cost Optimizer
        """

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )

        logger.info("Cost optimization notification sent successfully")

    except Exception as e:
        logger.error(f"Failed to send notification: {str(e)}")


def format_ec2_recommendations(recommendations: List[Dict[str, Any]]) -> str:
    """Format EC2 recommendations for notification"""
    if not recommendations:
        return "  No opportunities found"

    formatted = []
    for rec in recommendations[:5]:  # Limit to top 5
        formatted.append(f"  • {rec['instance_id']}: {rec['current_type']} → {rec['suggested_type']} (${rec['monthly_savings']:.2f}/month)")

    if len(recommendations) > 5:
        formatted.append(f"  ... and {len(recommendations) - 5} more")

    return "\n".join(formatted)


def format_rds_recommendations(recommendations: List[Dict[str, Any]]) -> str:
    """Format RDS recommendations for notification"""
    if not recommendations:
        return "  No opportunities found"

    formatted = []
    for rec in recommendations:
        formatted.append(f"  • {rec['instance_id']}: {rec['current_class']} → {rec['suggested_class']} (${rec['monthly_savings']:.2f}/month)")

    return "\n".join(formatted)


def format_s3_recommendations(recommendations: List[Dict[str, Any]]) -> str:
    """Format S3 recommendations for notification"""
    if not recommendations:
        return "  No opportunities found"

    formatted = []
    for rec in recommendations:
        formatted.append(f"  • {rec['bucket_name']}: Implement lifecycle policy (${rec['monthly_savings']:.2f}/month)")

    return "\n".join(formatted)


def format_ri_recommendations(recommendations: List[Dict[str, Any]]) -> str:
    """Format Reserved Instance recommendations for notification"""
    if not recommendations:
        return "  No opportunities found"

    formatted = []
    for rec in recommendations[:3]:  # Limit to top 3
        formatted.append(f"  • {rec['instance_type']}: {rec['recommended_instances']} instances (${rec['monthly_savings']:.2f}/month)")

    return "\n".join(formatted)


def send_error_notification(error_message: str) -> None:
    """Send error notification"""
    if not SNS_TOPIC_ARN:
        return

    try:
        subject = f"🚨 Cost Optimization Analysis Failed - {PROJECT_NAME} {ENVIRONMENT}"
        message = f"""
Cost Optimization Analysis Failed
=================================

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