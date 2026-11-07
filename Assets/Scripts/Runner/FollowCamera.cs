using UnityEngine;
namespace PersianRunner
{
    public sealed class FollowCamera : MonoBehaviour
    {
        [SerializeField] Transform target;
        [SerializeField] Vector3 offset = new Vector3(0, 5.2f, -8.5f);
        [SerializeField] float smooth = 6f;
        public void SetTarget(Transform value) => target = value;
        void LateUpdate()
        {
            if (!target) return;
            transform.position = Vector3.Lerp(transform.position, target.position + offset, smooth * Time.deltaTime);
            transform.LookAt(target.position + Vector3.up * 1.1f + Vector3.forward * 3f);
        }
    }
}