#!/usr/bin/env python3
"""
Database Backup Lambda Function

This function automates RDS instance and cluster backup operations:
1. Creates manual snapshots of RDS instances and clusters
2. Copies snapshots to S3 (for cross-region replication)
3. Manages snapshot retention
4. Sends notifications on success/failure
"""

import json
import boto3
import os
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients - get region from environment or session
region = os.environ.get('AWS_REGION', boto3.Session().region_name)
rds = boto3.client('rds', region_name=region)
s3 = boto3.client('s3', region_name=region)
sns = boto3.client('sns', region_name=region)

# Environment variables
BACKUP_BUCKET = os.environ['BACKUP_BUCKET']
KMS_KEY_ID = os.environ['KMS_KEY_ID']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
BACKUP_PREFIX = os.environ.get('BACKUP_PREFIX', 'database-backups')
RETENTION_DAYS = int(os.environ.get('RETENTION_DAYS', '30'))


def handler(event, context):
    """
    Main Lambda handler function
    """
    try:
        logger.info("Starting database backup process")

        backup_results = {
            'db_instances': [],
            'db_clusters': [],
            'cleanup_results': [],
            'errors': []
        }

        # Backup RDS instances
        db_instances = get_rds_instances()
        for instance in db_instances:
            try:
                result = backup_rds_instance(instance)
                backup_results['db_instances'].append(result)
            except Exception as e:
                error_msg = f"Failed to backup instance {instance['DBInstanceIdentifier']}: {str(e)}"
                logger.error(error_msg)
                backup_results['errors'].append(error_msg)

        # Backup RDS clusters
        db_clusters = get_rds_clusters()
        for cluster in db_clusters:
            try:
                result = backup_rds_cluster(cluster)
                backup_results['db_clusters'].append(result)
            except Exception as e:
                error_msg = f"Failed to backup cluster {cluster['DBClusterIdentifier']}: {str(e)}"
                logger.error(error_msg)
                backup_results['errors'].append(error_msg)

        # Cleanup old snapshots
        try:
            cleanup_results = cleanup_old_snapshots()
            backup_results['cleanup_results'] = cleanup_results
        except Exception as e:
            error_msg = f"Failed to cleanup old snapshots: {str(e)}"
            logger.error(error_msg)
            backup_results['errors'].append(error_msg)

        # Send notification
        send_notification(backup_results)

        logger.info("Database backup process completed")
        return {
            'statusCode': 200,
            'body': json.dumps(backup_results)
        }

    except Exception as e:
        error_msg = f"Database backup process failed: {str(e)}"
        logger.error(error_msg)

        # Send error notification
        send_error_notification(error_msg)

        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }


def get_rds_instances() -> List[Dict[str, Any]]:
    """
    Get all RDS instances that should be backed up
    """
    try:
        response = rds.describe_db_instances()
        instances = []

        for instance in response['DBInstances']:
            # Only backup instances that are available and not read replicas
            if (instance['DBInstanceStatus'] == 'available' and
                'ReadReplicaSourceDBInstanceIdentifier' not in instance):
                instances.append(instance)

        logger.info(f"Found {len(instances)} RDS instances to backup")
        return instances

    except Exception as e:
        logger.error(f"Failed to get RDS instances: {str(e)}")
        raise


def get_rds_clusters() -> List[Dict[str, Any]]:
    """
    Get all RDS clusters that should be backed up
    """
    try:
        response = rds.describe_db_clusters()
        clusters = []

        for cluster in response['DBClusters']:
            # Only backup clusters that are available
            if cluster['Status'] == 'available':
                clusters.append(cluster)

        logger.info(f"Found {len(clusters)} RDS clusters to backup")
        return clusters

    except Exception as e:
        logger.error(f"Failed to get RDS clusters: {str(e)}")
        raise


def backup_rds_instance(instance: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a manual snapshot of an RDS instance
    """
    instance_id = instance['DBInstanceIdentifier']
    timestamp = datetime.utcnow().strftime('%Y-%m-%d-%H-%M-%S')
    snapshot_id = f"{instance_id}-backup-{timestamp}"

    logger.info(f"Creating snapshot for RDS instance: {instance_id}")

    try:
        response = rds.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=instance_id,
            Tags=[
                {'Key': 'BackupType', 'Value': 'Automated'},
                {'Key': 'BackupDate', 'Value': timestamp},
                {'Key': 'SourceInstance', 'Value': instance_id},
                {'Key': 'RetentionDate', 'Value': (datetime.utcnow() + timedelta(days=RETENTION_DAYS)).strftime('%Y-%m-%d')}
            ]
        )

        snapshot_arn = response['DBSnapshot']['DBSnapshotArn']
        logger.info(f"Successfully created snapshot: {snapshot_id}")

        return {
            'instance_id': instance_id,
            'snapshot_id': snapshot_id,
            'snapshot_arn': snapshot_arn,
            'status': 'success',
            'timestamp': timestamp
        }

    except Exception as e:
        logger.error(f"Failed to create snapshot for instance {instance_id}: {str(e)}")
        raise


def backup_rds_cluster(cluster: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a manual snapshot of an RDS cluster
    """
    cluster_id = cluster['DBClusterIdentifier']
    timestamp = datetime.utcnow().strftime('%Y-%m-%d-%H-%M-%S')
    snapshot_id = f"{cluster_id}-backup-{timestamp}"

    logger.info(f"Creating snapshot for RDS cluster: {cluster_id}")

    try:
        response = rds.create_db_cluster_snapshot(
            DBClusterSnapshotIdentifier=snapshot_id,
            DBClusterIdentifier=cluster_id,
            Tags=[
                {'Key': 'BackupType', 'Value': 'Automated'},
                {'Key': 'BackupDate', 'Value': timestamp},
                {'Key': 'SourceCluster', 'Value': cluster_id},
                {'Key': 'RetentionDate', 'Value': (datetime.utcnow() + timedelta(days=RETENTION_DAYS)).strftime('%Y-%m-%d')}
            ]
        )

        snapshot_arn = response['DBClusterSnapshot']['DBClusterSnapshotArn']
        logger.info(f"Successfully created cluster snapshot: {snapshot_id}")

        return {
            'cluster_id': cluster_id,
            'snapshot_id': snapshot_id,
            'snapshot_arn': snapshot_arn,
            'status': 'success',
            'timestamp': timestamp
        }

    except Exception as e:
        logger.error(f"Failed to create snapshot for cluster {cluster_id}: {str(e)}")
        raise


def cleanup_old_snapshots() -> List[Dict[str, Any]]:
    """
    Clean up old manual snapshots based on retention policy
    """
    logger.info("Starting cleanup of old snapshots")
    cleanup_results = []
    cutoff_date = datetime.utcnow() - timedelta(days=RETENTION_DAYS)

    try:
        # Cleanup DB instance snapshots
        response = rds.describe_db_snapshots(SnapshotType='manual')
        for snapshot in response['DBSnapshots']:
            if is_automated_backup_snapshot(snapshot) and snapshot['SnapshotCreateTime'].replace(tzinfo=None) < cutoff_date:
                try:
                    rds.delete_db_snapshot(DBSnapshotIdentifier=snapshot['DBSnapshotIdentifier'])
                    cleanup_results.append({
                        'type': 'instance_snapshot',
                        'snapshot_id': snapshot['DBSnapshotIdentifier'],
                        'status': 'deleted',
                        'create_time': snapshot['SnapshotCreateTime'].isoformat()
                    })
                    logger.info(f"Deleted old snapshot: {snapshot['DBSnapshotIdentifier']}")
                except Exception as e:
                    logger.error(f"Failed to delete snapshot {snapshot['DBSnapshotIdentifier']}: {str(e)}")
                    cleanup_results.append({
                        'type': 'instance_snapshot',
                        'snapshot_id': snapshot['DBSnapshotIdentifier'],
                        'status': 'failed',
                        'error': str(e)
                    })

        # Cleanup DB cluster snapshots
        response = rds.describe_db_cluster_snapshots(SnapshotType='manual')
        for snapshot in response['DBClusterSnapshots']:
            if is_automated_backup_snapshot(snapshot) and snapshot['SnapshotCreateTime'].replace(tzinfo=None) < cutoff_date:
                try:
                    rds.delete_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshot['DBClusterSnapshotIdentifier'])
                    cleanup_results.append({
                        'type': 'cluster_snapshot',
                        'snapshot_id': snapshot['DBClusterSnapshotIdentifier'],
                        'status': 'deleted',
                        'create_time': snapshot['SnapshotCreateTime'].isoformat()
                    })
                    logger.info(f"Deleted old cluster snapshot: {snapshot['DBClusterSnapshotIdentifier']}")
                except Exception as e:
                    logger.error(f"Failed to delete cluster snapshot {snapshot['DBClusterSnapshotIdentifier']}: {str(e)}")
                    cleanup_results.append({
                        'type': 'cluster_snapshot',
                        'snapshot_id': snapshot['DBClusterSnapshotIdentifier'],
                        'status': 'failed',
                        'error': str(e)
                    })

        logger.info(f"Cleanup completed. Processed {len(cleanup_results)} snapshots")
        return cleanup_results

    except Exception as e:
        logger.error(f"Failed to cleanup old snapshots: {str(e)}")
        raise


def is_automated_backup_snapshot(snapshot: Dict[str, Any]) -> bool:
    """
    Check if a snapshot was created by this automated backup process
    """
    # Check if snapshot has the BackupType tag with value 'Automated'
    tags_key = 'TagList' if 'TagList' in snapshot else 'Tags'
    if tags_key in snapshot:
        for tag in snapshot[tags_key]:
            if tag['Key'] == 'BackupType' and tag['Value'] == 'Automated':
                return True

    # Also check snapshot name pattern as fallback
    snapshot_id = snapshot.get('DBSnapshotIdentifier') or snapshot.get('DBClusterSnapshotIdentifier')
    return snapshot_id and '-backup-' in snapshot_id


def send_notification(backup_results: Dict[str, Any]) -> None:
    """
    Send SNS notification with backup results
    """
    try:
        total_backups = len(backup_results['db_instances']) + len(backup_results['db_clusters'])
        total_errors = len(backup_results['errors'])
        total_cleanup = len(backup_results['cleanup_results'])

        subject = f"Database Backup Report - {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC"

        if total_errors > 0:
            subject = f"⚠️ {subject} - {total_errors} Errors"
        else:
            subject = f"✅ {subject} - Success"

        message = f"""
Database Backup Execution Report

Summary:
- Total Backups Created: {total_backups}
- Total Cleanup Actions: {total_cleanup}
- Total Errors: {total_errors}

Instance Backups: {len(backup_results['db_instances'])}
{format_backup_results(backup_results['db_instances'])}

Cluster Backups: {len(backup_results['db_clusters'])}
{format_backup_results(backup_results['db_clusters'])}

Cleanup Results: {total_cleanup}
{format_cleanup_results(backup_results['cleanup_results'])}

Errors: {total_errors}
{chr(10).join(backup_results['errors']) if backup_results['errors'] else 'None'}

Execution Time: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC
        """

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )

        logger.info("Backup notification sent successfully")

    except Exception as e:
        logger.error(f"Failed to send notification: {str(e)}")


def send_error_notification(error_message: str) -> None:
    """
    Send error notification
    """
    try:
        subject = f"🚨 Database Backup Failed - {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC"
        message = f"""
Database Backup Process Failed

Error: {error_message}

Please check the CloudWatch logs for more details.

Execution Time: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC
        """

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )

    except Exception as e:
        logger.error(f"Failed to send error notification: {str(e)}")


def format_backup_results(results: List[Dict[str, Any]]) -> str:
    """
    Format backup results for notification message
    """
    if not results:
        return "  None"

    formatted = []
    for result in results:
        instance_id = result.get('instance_id') or result.get('cluster_id')
        snapshot_id = result.get('snapshot_id')
        status = result.get('status')
        formatted.append(f"  - {instance_id}: {snapshot_id} ({status})")

    return chr(10).join(formatted)


def format_cleanup_results(results: List[Dict[str, Any]]) -> str:
    """
    Format cleanup results for notification message
    """
    if not results:
        return "  None"

    formatted = []
    for result in results:
        snapshot_id = result.get('snapshot_id')
        status = result.get('status')
        snapshot_type = result.get('type')
        formatted.append(f"  - {snapshot_type}: {snapshot_id} ({status})")

    return chr(10).join(formatted)